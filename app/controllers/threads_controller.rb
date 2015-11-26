class ThreadsController < ApplicationController
  before_action :logged_in_user

  def show
  	thread_db = EmailThread.where(synced: true).find_by(id: params['id'])
    if !thread_db.nil? and thread_db.authorisation.enabled and current_user == (thread_db.authorisation.granter or thread_db.authorisation.requester)
      @thread = thread_db
	  	@emails = GmailSync.get_emails(@thread.authorisation, @thread.thread_id).sort_by { |e| e.internal_date }.reverse
      @message_attachments = @thread.message_attachments
	 end
   render layout: !request.xhr?
  end

  def update_tags
  	thread = current_user.email_threads.find_by(id: params['thread_id'])
  	if !thread.nil?
  		if params[:tag_highlight] # Thread to be highlighted
  			thread.set_highlight(true)
  		else
  			thread.set_highlight(false)
  		end
  	end
  	respond_to do |format|
      format.js
    end
  end
end
