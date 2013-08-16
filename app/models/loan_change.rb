class LoanChange < LoanModification
  ALLOWED_CHANGE_TYPE_IDS = [
    ChangeType::CapitalRepaymentHoliday,
    ChangeType::ChangeRepayments,
    ChangeType::ExtendTerm,
    ChangeType::LenderDemandSatisfied,
    ChangeType::LumpSumRepayment,
    ChangeType::RecordAgreedDraw,
    ChangeType::ReprofileDraws,
    ChangeType::DecreaseTerm,
    ChangeType::RepaymentFrequency,
  ].map(&:id)

  validates_inclusion_of :change_type_id, in: ALLOWED_CHANGE_TYPE_IDS, strict: true
  validate :validate_non_negative_amounts

  def repayment_frequency
    RepaymentFrequency.find(repayment_frequency_id)
  end

  def old_repayment_frequency
    RepaymentFrequency.find(old_repayment_frequency_id)
  end

  private
    def validate_non_negative_amounts
      errors.add(:amount_drawn, :not_be_negative) if amount_drawn && amount_drawn < 0
      errors.add(:lump_sum_repayment, :not_be_negative) if lump_sum_repayment && lump_sum_repayment < 0
    end
end
