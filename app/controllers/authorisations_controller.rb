class AuthorisationsController < ApplicationController
  before_action :logged_in_user

  def index
  	@authorisations = current_user.requested_authorisations.all.order('created_at desc')
    @users = User.all
    respond_to do |format|
      format.html
      format.js
    end
  end

  def show
  	@authorisation = current_user.requested_authorisations.find(params[:id])
  	if @authorisation.nil? or !@authorisation.enabled or !@authorisation.synced
  		flash[:alert] = "Either you are not authorised anymore or it hasn't finished syncing"
  		redirect_to authorisations_path
  	end
  	params[:tab_filter] = 'highlight' if params['tab_filter'].nil? # default tab
    @tab_filter = params[:tab_filter]
    params_filters = params.slice(:tab_filter)
    @threads = @authorisation.email_threads.joins(:tags).where(synced: true).filter(params_filters).includes(:email_messages, :message_attachments, :message_participants, :participants).distinct.all.paginate(page: params[:page], :per_page => 10)
    respond_to do |format|
      format.html
      format.js
    end
  end

  def requesting
    @authorisation = Authorisation.new
  end

  def granting
    @authorisations = current_user.granted_authorisations.all.order('created_at desc')
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
