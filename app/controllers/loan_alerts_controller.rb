class LoanAlertsController < ApplicationController

  include LoanAlerts

  def not_progressed
    start_date, end_date = start_and_end_dates(NotProgressedStartDate, NotProgressedEndDate)

    @loans = not_progressed_loans(start_date, end_date)
    @title = I18n.t('dashboard.loan_alerts.not_progressed')
    render "show"
  end

  def not_drawn
    start_date, end_date = start_and_end_dates(NotDrawnStartDate, NotDrawnEndDate)

    @loans = not_drawn_loans(start_date, end_date)
    @title = I18n.t('dashboard.loan_alerts.not_drawn')
    render "show"
  end

  def demanded
    start_date, end_date = start_and_end_dates(DemandedStartDate, DemandedEndDate)

    @loans = demanded_loans(start_date, end_date)
    @title = I18n.t('dashboard.loan_alerts.demanded')
    render "show"
  end

  def assumed_repaid
    offered_start_date, offered_end_date = start_and_end_dates(AssumedRepaidOfferedStartDate, AssumedRepaidOfferedEndDate)
    guaranteed_start_date, guaranteed_end_date = start_and_end_dates(AssumedRepaidGuaranteedStartDate, AssumedRepaidGuaranteedEndDate)

    @loans = (
      assumed_repaid_offered_loans(offered_start_date, offered_end_date) +
        assumed_repaid_guaranteed_loans(guaranteed_start_date, guaranteed_end_date)
    ).sort_by(&:updated_at)
    @title = I18n.t('dashboard.loan_alerts.assumed_repaid')
    render "show"
  end

  private

  def start_and_end_dates(default_start_date, default_end_date)
    default_start_date = default_start_date.to_date
    default_start_date = default_start_date.to_date

    case params[:priority]
    when "high"
      start_date = default_start_date
      end_date = (default_start_date + 9.days)
    when "medium"
      start_date = (default_start_date + 10.days)
      end_date = (default_start_date + 29.days)
    when "low"
      start_date = (default_start_date + 30.days)
      end_date = (default_start_date + 59.days)
    else
      start_date = default_start_date
      end_date = default_end_date
    end

    return start_date.to_date, end_date.to_date
  end

end