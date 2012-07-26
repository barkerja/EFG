class LoanRecoveriesCsvExport < BaseCsvExport

  private

  def fields
    %w(
      reference
      business_name
      recovered_on
      dti_demand_outstanding
      amount_due_to_dti
    )
  end

  def csv_row(record)
    [
      record.loan.reference,
      record.loan.business_name,
      record.recovered_on.strftime('%d/%m/%Y'),
      record.loan.dti_demand_outstanding.try(:format),
      record.amount_due_to_dti.try(:format)
    ]
  end

end