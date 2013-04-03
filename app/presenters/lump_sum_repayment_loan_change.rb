class LumpSumRepaymentLoanChange < LoanChangePresenter
  attr_reader :lump_sum_repayment
  attr_accessible :lump_sum_repayment

  validate :validate_lump_sum_repayment

  def lump_sum_repayment=(value)
    @lump_sum_repayment = value.present? ? Money.parse(value) : nil
  end

  private
    def amount_available
      loan.amount - loan.cumulative_lump_sum_amount
    end

    def update_loan_change
      loan_change.change_type_id = ChangeType::LumpSumRepayment.id
      loan_change.lump_sum_repayment = lump_sum_repayment
    end

    def validate_lump_sum_repayment
      if lump_sum_repayment.nil?
        errors.add(:lump_sum_repayment, :required)
      elsif lump_sum_repayment <= 0
        errors.add(:lump_sum_repayment, :must_be_greater_than_zero)
      elsif lump_sum_repayment > amount_available
        errors.add(:lump_sum_repayment, :exceeds_amount_available)
      end
    end
end