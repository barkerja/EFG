class LoanStatesController < ApplicationController
  before_filter :verify_view_permission

  def index
    @loan_states = LoanStates.new(current_lender).states
  end

  def show
    scope = current_lender.loans.with_state(params[:id])
    scope = scope.with_scheme(params[:scheme]) if params[:scheme].present?

    respond_to do |format|
      format.html {
        @loans = scope.paginate(per_page: 50, page: params[:page])
      }
      format.csv {
        loans = scope.includes(:initial_draw_change)
        csv_export = LoanCsvExport.new(loans)
        filename = "#{params[:id]}_loans_#{Date.current.to_s(:db)}.csv"
        stream_response(csv_export, filename)
      }
    end
  end

  private
    def verify_view_permission
      enforce_view_permission(LoanStates)
    end
end
