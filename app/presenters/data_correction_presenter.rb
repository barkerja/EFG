require 'active_model/model'

class DataCorrectionPresenter
  include ActiveModel::Model
  include ActiveModel::MassAssignmentSecurity
  extend  ActiveModel::Callbacks

  def self.model_name
    ActiveModel::Name.new(self, nil, 'DataCorrection')
  end

  define_model_callbacks :save

  attr_reader :created_by, :loan

  def initialize(loan, created_by)
    @loan = loan
    @created_by = created_by
  end

  def attributes=(attributes)
    sanitize_for_mass_assignment(attributes).each do |k, v|
      public_send("#{k}=", v)
    end
  end

  def data_correction
    @data_correction ||= loan.data_corrections.new
  end

  def save
    return false unless valid?

    loan.transaction do
      run_callbacks :save do
        data_correction.change_type = ChangeType::DataCorrection unless data_correction.change_type
        data_correction.created_by = created_by
        data_correction.date_of_change = Date.current
        data_correction.modified_date = Date.current
        data_correction.save!

        loan.last_modified_at = Time.now
        loan.modified_by = created_by
        loan.save!
      end
    end

    true
  end
end
