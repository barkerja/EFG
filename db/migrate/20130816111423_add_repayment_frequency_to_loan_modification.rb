class AddRepaymentFrequencyToLoanModification < ActiveRecord::Migration
  def change
    add_column :loan_modifications, :repayment_frequency_id, :integer
    add_column :loan_modifications, :old_repayment_frequency_id, :integer
  end
end
