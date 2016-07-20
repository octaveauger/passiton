class DelegationsController < ApplicationController
  before_action :logged_in_user
  before_action :is_manager, only: [:index, :new, :create, :cancel]

  def index
  	@delegations = current_user.managed_delegations.all.order('created_at desc')
  end

  def new
  	@delegation = current_user.managed_delegations.new
  end

  def create
  	@delegation = current_user.managed_delegations.new(delegation_params)
    @delegation.employee_id = User.find_or_create_guest(params['delegation']['employee_email']).id
    delegation_db = Delegation.find_by(manager_id: current_user.id, employee_id: @delegation.employee_id)
    @delegation = delegation_db if delegation_db #select existing delegation if it already exists for this manager + employee
    if @delegation.save
      DelegationMailer.request_delegation(@delegation).deliver
      flash[:notice] = 'Request sent!'
      redirect_to delegations_path and return
    else
      flash[:alert] = 'Something went wrong, try again'
      render 'new'
    end
  end

  # Confirmation (only by employee)
  def confirm
  	@delegation = current_user.employee_delegations.find_by(token: params[:delegation_id])
  	if @delegation.nil?
  		flash[:alert] = 'You are not authorised to access this page'
  		redirect_to root_path and return
  	else
  		@delegation.activate
  		flash[:notice] = 'Request confirmed! Your account is now controlled by ' + @delegation.manager.full_identity
      redirect_to root_path and return
  	end
  end

  # Revoke (only by employee -> mirror of cancel)
  def revoke
    @delegation = current_user.employee_delegations.find_by(token: params[:delegation_id])
    if @delegation.nil?
      flash[:alert] = 'You are not authorised to access this page'
      redirect_to root_path and return
    else
      @delegation.deactivate('employee')
      flash[:notice] = 'Confirmed! Your account is no longer controlled by ' + @delegation.manager.full_identity
      redirect_to root_path and return
    end
  end

   # Cancellation (only by manager -> mirror of revoke)
  def cancel
    @delegation = current_user.managed_delegations.find_by(token: params[:delegation_id])
    if @delegation.nil?
      flash[:alert] = 'You are not authorised to access this page'
      redirect_to delegations_path and return
    else
      @delegation.deactivate('manager')
      flash[:notice] = 'Confirmed! You no longer control the account of ' + @delegation.employee.full_identity
      redirect_to delegations_path and return
    end
  end

  private

    def delegation_params
      params.require(:delegation).permit(:employee_email, :description)
    end
end
