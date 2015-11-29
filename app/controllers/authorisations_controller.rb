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
  	@authorisation = current_user.granted_authorisations.find_by(id: params[:id])
    if @authorisation.nil?
      @authorisation = current_user.requested_authorisations.find_by(id: params[:id])
      @viewer_type = 'requester' # if user is both granter and requester, they'll be seen as requester in the view
    else
      @viewer_type = 'granter'
    end

    # Handling the case of someone requesting from themselves
    if !@authorisation.nil? and @authorisation.requester_id == @authorisation.granter_id
      if @authorisation.enabled
        @viewer_type = 'requester'
      else
        @viewer_type = 'granter'
      end
    end

  	if @authorisation.nil? or (!@authorisation.enabled and @viewer_type == 'requester') or !@authorisation.synced
  		flash[:alert] = "Either you are not authorised anymore or it hasn't finished syncing" + @viewer_type
  		redirect_to authorisations_path and return
  	end

  	tab_selected = !params['tab_filter'].nil?
    params[:tab_filter] = 'highlight' if params['tab_filter'].nil? # default tab
    @tab_filter = params[:tab_filter]
    params_filters = params.slice(:tab_filter)

    # Handling searches
    if params['search'] and !params['search'].blank?
      @search = @authorisation.authorisation_searches.find_by(scope: params['search'])
      @search = @authorisation.authorisation_searches.create(scope: params['search']) if @search.nil?
      @tab_filter = 'search'
      Rails.logger.info('Auth search started for scope: ' + @authorisation.scope + ' ' + params['search'] + ' and id: ' + @authorisation.id.to_s)
      found_threads = GmailSync.search_threads(@authorisation, @search)
      Rails.logger.info('Auth search completed for scope: ' + @authorisation.scope + params['search'] + ' and id: ' + @authorisation.id.to_s + ' with found thread count: ' + found_threads.count.to_s)
      @threads = @authorisation.email_threads.by_latest_email.joins(:tags).where(synced: true).where(thread_id: found_threads).includes(:message_attachments, :message_participants, :participants).distinct.all.paginate(page: params[:page], :per_page => 10)
    else
      if !tab_selected and @authorisation.email_threads.joins(:tags).where(synced: true).filter(params_filters).empty?
        params[:tab_filter] = 'all'
        @tab_filter = 'all'
        params_filters = params.slice(:tab_filter)
      end
      @threads = @authorisation.email_threads.by_latest_email.joins(:tags).where(synced: true).filter(params_filters).includes(:message_attachments, :message_participants, :participants).distinct.all.paginate(page: params[:page], :per_page => 10)
    end

    @searches = @authorisation.authorisation_searches.order('id desc').limit(5).all

    @container = false
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
    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    @authorisation = Authorisation.new(authorisation_params)
    @authorisation.requester_id = current_user.id
    @authorisation.granter_id = User.find_or_create_guest(params['authorisation']['granter_email']).id
    @authorisation.status = 'pending'
    if @authorisation.save
      if !@authorisation.granter.guest
        Rails.logger.info('Auth controller create - gmail sync launched from requester')
        @authorisation.sync_job(true, 'requester') # Get started syncing the authorisation
      else
        AuthorisationMailer.request_authorisation(@authorisation).deliver # Email the granter since we can't sync with guests
      end
      flash[:notice] = 'Context requested!'
      redirect_to authorisations_path and return
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
      redirect_to authorisation_grant_path and return
    end
  end

  private

    def authorisation_params
      params.require(:authorisation).permit(:scope, :description)
    end
end
