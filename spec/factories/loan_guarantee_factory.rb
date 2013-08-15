FactoryGirl.define do
  factory :loan_guarantee do
    received_declaration true
    signed_direct_debit_received true
    first_pp_received true
    initial_draw_date Date.current

    initialize_with {
      loan = FactoryGirl.build(:loan, :offered)
      new(loan)
    }
  end
end
