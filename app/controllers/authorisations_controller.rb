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
    @granter = User.find(params[:granter_id])
    if @granter.nil?
      redirect_to authorisations_path
    end
    @authorisation = Authorisation.new(requester: current_user, granter: @granter)
  end

  def granting
    @authorisations = current_user.granted_authorisations.all
  end

  def create
    @authorisation = Authorisation.new(authorisation_params)
    @authorisation.requester_id = current_user.id
    @authorisation.enabled = false
    if @authorisation.save
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
      @authorisation.update(enabled: params['authorisation']['enabled'])
      redirect_to authorisation_grant_path
    end
  end

  private

    def authorisation_params
      params.require(:authorisation).permit(:granter_id, :requester_id, :scope, :enabled)
    end
end
