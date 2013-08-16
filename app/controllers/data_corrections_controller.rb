class DataCorrectionsController < ApplicationController
  TYPES = {
    'business_name' => BusinessNameDataCorrection,
    'demanded_amount' => DemandedAmountDataCorrection,
    'sortcode' => SortcodeDataCorrection
  }

  before_filter :verify_create_permission
  before_filter :load_loan
  before_filter :load_presenter_or_redirect, only: [:new, :create]

  def index
  end

  def new
  end

  def create
    @presenter.attributes = params[:data_correction]

    if @presenter.save
      redirect_to loan_url(@loan)
    else
      render :new
    end
  end

  private
    def load_loan
      @loan = current_lender.loans.correctable.find(params[:loan_id])
    end

    def load_presenter_or_redirect
      klass = TYPES[params[:type]]

      if klass
        @presenter = klass.new(@loan, current_user)
      else
        redirect_to action: :index
      end
    end

    def verify_create_permission
      enforce_create_permission(DataCorrection)
    end
end
