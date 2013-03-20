class PremiumSchedule < ActiveRecord::Base
  include FormatterConcern

  SCHEDULE_TYPE = 'S'.freeze
  RESCHEDULE_TYPE = 'R'.freeze
  NOTIFIED_AID_TYPE = 'N'.freeze

  EURO_CONVERSION_RATE = BigDecimal.new('1.2285')
  MAX_INITIAL_DRAW = Money.new(9_999_999_99)
  RISK_FACTOR = 0.3

  PREMIUM_CALCULATION_STRATEGIES = {
    annually: LegacyQuarterlyPremiumPaymentCollection,
    six_monthly: LegacyQuarterlyPremiumPaymentCollection,
    quarterly: LegacyQuarterlyPremiumPaymentCollection,
    monthly: LegacyQuarterlyPremiumPaymentCollection,
    interest_only: InterestOnlyPremiumPaymentCollection,
    legacy_quarterly: LegacyQuarterlyPremiumPaymentCollection
  }

  belongs_to :loan, inverse_of: :premium_schedules

  attr_accessible :initial_draw_year, :initial_draw_amount,
    :repayment_duration, :initial_capital_repayment_holiday,
    :second_draw_amount, :second_draw_months, :third_draw_amount,
    :third_draw_months, :fourth_draw_amount, :fourth_draw_months,
    :loan_id, :premium_cheque_month

  before_validation :set_seq, on: :create
  before_validation :set_premium_calculation_strategy, on: :create

  before_save do
    write_attribute(:euro_conversion_rate, euro_conversion_rate)
  end

  after_save do |calculation|
    calculation.loan.update_attribute :state_aid, state_aid_eur
  end

  validates_presence_of :loan_id, strict: true
  validates_presence_of :repayment_duration
  validates_presence_of :premium_calculation_strategy
  validates_inclusion_of :calc_type, in: [ SCHEDULE_TYPE, RESCHEDULE_TYPE, NOTIFIED_AID_TYPE ]
  validates_presence_of :initial_draw_year, unless: :reschedule?
  validates_format_of :premium_cheque_month, with: /\A\d{2}\/\d{4}\z/, if: :reschedule?, message: :invalid_format

  %w(initial_capital_repayment_holiday second_draw_months third_draw_months fourth_draw_months).each do |attr|
    validates_inclusion_of attr, in: 0..120, allow_blank: true, message: :invalid
  end

  validate :premium_cheque_month_in_the_future, if: :reschedule?
  validate :initial_draw_amount_is_within_limit
  validate :total_draw_amount_less_than_or_equal_to_loan_amount

  format :initial_draw_amount, with: MoneyFormatter.new
  format :second_draw_amount, with: MoneyFormatter.new
  format :third_draw_amount, with: MoneyFormatter.new
  format :fourth_draw_amount, with: MoneyFormatter.new

  def self.current_euro_conversion_rate
    EURO_CONVERSION_RATE
  end

  def state_aid_gbp
    (loan.amount * (loan.guarantee_rate / 100) * RISK_FACTOR) - total_premiums
  end

  def state_aid_eur
    euro = state_aid_gbp * euro_conversion_rate
    Money.new(euro.cents, 'EUR')
  end

  def reschedule?
    calc_type == RESCHEDULE_TYPE
  end

  def euro_conversion_rate
    read_attribute(:euro_conversion_rate) || self.class.current_euro_conversion_rate
  end

  def reset_euro_conversion_rate
    self.euro_conversion_rate = self.class.current_euro_conversion_rate
  end

  def drawdowns
    drawdowns = [TrancheDrawdown.new(initial_draw_amount, 0)]

    if second_draw_amount.present? && second_draw_amount.nonzero? && second_draw_months.present? && second_draw_months.nonzero?
      drawdowns << TrancheDrawdown.new(second_draw_amount, second_draw_months)
    end

    if third_draw_amount.present? && third_draw_amount.nonzero? && third_draw_months.present? && third_draw_months.nonzero?
      drawdowns << TrancheDrawdown.new(third_draw_amount, third_draw_months)
    end

    if fourth_draw_amount.present? && fourth_draw_amount.nonzero? && fourth_draw_months.present? && fourth_draw_months.nonzero?
      drawdowns << TrancheDrawdown.new(fourth_draw_amount, fourth_draw_months)
    end

    drawdowns
  end

  def premiums
    premium_payment_collection_class.new(self).to_a
  end

  def total_premiums
    premiums.sum
  end

  def initial_draw_date
    loan.initial_draw_change.try :date_of_change
  end

  def subsequent_premiums
    @subsequent_premiums ||= reschedule? ? premiums : premiums[1..-1]
  end

  def number_of_subsequent_payments
    subsequent_premiums.count
  end

  def total_subsequent_premiums
    subsequent_premiums.sum
  end

  # This returns a string because its not really a valid date and it doesn't
  # have a day. We could just pick an arbitary day, but then it might be
  # tempting to (incorrectly) format it in the view with the day shown.
  def second_premium_collection_month
    return unless initial_draw_date
    initial_draw_date.advance(months: 3).strftime('%m/%Y')
  end

  def initial_premium_cheque
    reschedule? ? Money.new(0) : premiums.first
  end

  def repayment_holiday_active_at_month?(month)
    initial_capital_repayment_holiday >= month
  end

  def initial_capital_repayment_holiday
    # Force nil => 0
    super.to_i
  end

  def premium_rate_per_quarter
    loan.premium_rate / 100 / 4
  end

  private
    def set_seq
      self.seq = (PremiumSchedule.where(loan_id: loan_id).maximum(:seq) || -1) + 1 unless seq
    end

    def set_premium_calculation_strategy
      return unless loan && loan.repayment_frequency
      write_attribute(:premium_calculation_strategy, loan.repayment_frequency.premium_calculation_strategy)
    end

    def initial_draw_amount_is_within_limit
      if initial_draw_amount.blank? || initial_draw_amount < 0 || initial_draw_amount > MAX_INITIAL_DRAW
        errors.add(:initial_draw_amount, :invalid)
      end
    end

    def premium_cheque_month_in_the_future
      begin
        date = Date.parse("01/#{premium_cheque_month}")
      rescue ArgumentError
        errors.add(:premium_cheque_month, :invalid_format)
        return
      end

      errors.add(:premium_cheque_month, :invalid) unless date > Date.today.end_of_month
    end

    def total_draw_amount
      drawdowns.map(&:amount).sum
    end

    def total_draw_amount_less_than_or_equal_to_loan_amount
      if loan.amount < total_draw_amount
        errors.add(:initial_draw_amount, :not_less_than_or_equal_to_loan_amount, loan_amount: loan.amount.format)
        errors.add(:second_draw_amount, :not_less_than_or_equal_to_loan_amount, loan_amount: loan.amount.format)
        errors.add(:third_draw_amount, :not_less_than_or_equal_to_loan_amount, loan_amount: loan.amount.format)
        errors.add(:fourth_draw_amount, :not_less_than_or_equal_to_loan_amount, loan_amount: loan.amount.format)
      end
    end

    def premium_payment_collection_class
      PREMIUM_CALCULATION_STRATEGIES.fetch(premium_calculation_strategy.to_sym)
    end
end
