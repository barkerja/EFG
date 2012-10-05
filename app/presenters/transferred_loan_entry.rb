class TransferredLoanEntry
  include LoanPresenter
  include LoanStateTransition

  transition from: [Loan::Incomplete], to: Loan::Completed, event: :complete

  attribute :viable_proposition, read_only: true
  attribute :would_you_lend, read_only: true
  attribute :collateral_exhausted, read_only: true
  attribute :sic_code, read_only: true
  attribute :loan_category_id, read_only: true
  attribute :reason_id, read_only: true
  attribute :previous_borrowing, read_only: true
  attribute :private_residence_charge_required, read_only: true
  attribute :personal_guarantee_required, read_only: true
  attribute :turnover, read_only: true
  attribute :trading_date, read_only: true
  attribute :lender, read_only: true
  attribute :reference, read_only: true
  attribute :business_name, read_only: true
  attribute :trading_name, read_only: true
  attribute :legal_form_id, read_only: true
  attribute :company_registration, read_only: true
  attribute :non_validated_postcode, read_only: true
  attribute :postcode, read_only: true
  attribute :town, read_only: true
  attribute :legacy_loan?, read_only: true

  attribute :declaration_signed
  attribute :sortcode
  attribute :amount
  attribute :repayment_duration
  attribute :repayment_frequency_id
  attribute :maturity_date
  attribute :state_aid_is_valid
  attribute :state_aid
  attribute :generic1
  attribute :generic2
  attribute :generic3
  attribute :generic4
  attribute :generic5

  validates_presence_of :amount, :repayment_duration, :repayment_frequency_id, :maturity_date

  validate :maturity_date_within_loan_term

  validate do
    errors.add(:declaration_signed, :accepted) unless self.declaration_signed
    errors.add(:state_aid, :calculated) unless self.loan.state_aid_calculation
  end

  def initialize(loan)
    super
    raise ArgumentError, 'loan is not a transferred loan' unless @loan.created_from_transfer?
  end

  def save_as_incomplete
    loan.state = Loan::Incomplete
    loan.save(validate: false)
  end

  private

  def maturity_date_within_loan_term
    return if maturity_date.blank? || loan_category_id.blank?

    loan_category = LoanCategory.find(loan_category_id)
    initial_draw_date = loan.initial_draw_change.date_of_change

    if maturity_date < initial_draw_date + loan_category.min_loan_term.months
      errors.add(:maturity_date, :less_than_min_loan_term)
    end

    if maturity_date > initial_draw_date + loan_category.max_loan_term.months
      errors.add(:maturity_date, :greater_than_max_loan_term)
    end
  end

end
