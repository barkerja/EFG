class SortcodeDataCorrection < DataCorrectionPresenter
  attr_accessor :sortcode
  attr_accessible :sortcode

  before_save :update_data_correction
  before_save :update_loan

  validates :sortcode, presence: true

  private
    def update_data_correction
      data_correction.sortcode = sortcode
      data_correction.old_sortcode = loan.sortcode
    end

    def update_loan
      loan.sortcode = sortcode
    end
end
