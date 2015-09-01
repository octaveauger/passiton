class AuthorisationsController < ApplicationController
  before_action :logged_in_user

  def index
  	@authorisations = current_user.requested_authorisations.all
    @users = User.all
  end

  def show
  	@authorisation = current_user.requested_authorisations.find(params[:id])
  	if @authorisation.nil? or !@authorisation.enabled or !@authorisation.synced
  		flash[:alert] = "Either you are not authorised anymore or it hasn't finished syncing"
  		redirect_to authorisations_path
  	end
  	@threads = @authorisation.email_threads.includes(:email_messages, :email_headers, :message_attachments, :attachment_headers).all.paginate(page: params[:page], :per_page => 10)
  end

  def requesting
    @authorisation = Authorisation.new
  end

  def granting
    @authorisations = current_user.granted_authorisations.all
  end

  def create
    @authorisation = Authorisation.new(authorisation_params)
    @authorisation.requester_id = current_user.id
    @authorisation.granter_id = User.find_or_create_guest(params['authorisation']['granter_email']).id
    @authorisation.status = 'pending'
    if @authorisation.save
      AuthorisationMailer.request_authorisation(@authorisation).deliver
      flash[:notice] = 'Authorisation requested!'
      redirect_to authorisations_path
    else
      flash[:alert] = 'Something went wrong, try again'
      render 'requesting'
    end
  end

  def update
    @authorisation = current_user.granted_authorisations.find(params[:id])
    if @authorisation.nil?
      flash[:alert] = 'Something went wrong, try again'
      render 'granting'
    else
      @authorisation.update_status(params['authorisation']['status'])
      redirect_to authorisation_grant_path
    end
  end

  private

    def authorisation_params
      params.require(:authorisation).permit(:scope, :description)
    end
end
