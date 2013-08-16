class RepaymentFrequencyLoanChange < LoanChangePresenter
  ValidRepaymentFrequencyIds = [
    RepaymentFrequency::Annually,
    RepaymentFrequency::SixMonthly,
    RepaymentFrequency::Quarterly,
    RepaymentFrequency::Monthly,
    RepaymentFrequency::InterestOnly,
  ].map(&:id)

  attr_accessible :repayment_frequency_id
  attr_accessor :repayment_frequency_id

  validates_inclusion_of :repayment_frequency_id, in: ValidRepaymentFrequencyIds
  validate :changed_repayment_frequency

  before_save :update_repayment_frequency_ids

  private

  def changed_repayment_frequency
    if loan.repayment_frequency_id == repayment_frequency_id
      errors.add(:repayment_frequency_id, :must_be_changed)
    end
  end

  def update_repayment_frequency_ids
    loan_change.change_type = ChangeType::RepaymentFrequency
    loan_change.repayment_frequency_id = repayment_frequency_id
    loan_change.old_repayment_frequency_id = loan.repayment_frequency_id

    loan.repayment_frequency_id = repayment_frequency_id
  end
end
