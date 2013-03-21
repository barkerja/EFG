FactoryGirl.define do
  factory :data_correction_presenter do
    association :created_by, factory: :lender_user
    loan

    factory :business_name_data_correction_presenter, class: BusinessNameDataCorrectionPresenter do
      business_name 'New Business Name'
    end

    factory :demanded_amount_data_correction_presenter, class: DemandedAmountDataCorrectionPresenter do
      demanded_amount Money.new(1_000_00)
      association :loan, factory: [:loan, :guaranteed, :demanded]
    end

    factory :sortcode_data_correction_presenter, class: SortcodeDataCorrectionPresenter do
      sortcode '123456'
    end
  end
end
