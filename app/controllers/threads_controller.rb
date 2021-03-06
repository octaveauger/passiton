class ThreadsController < ApplicationController
  before_action :logged_in_user

  def show
  	thread_db = EmailThread.where(synced: true).find_by(id: params['id'])
    if !thread_db.nil? and User.can_access_thread(thread_db.id, current_user.id)
      @thread = thread_db
	  	@emails = GmailSync.get_emails(@thread.authorisation, @thread.thread_id).sort_by { |e| e.internal_date }
      @message_attachments = @thread.message_attachments
    end
   render layout: !request.xhr?
  end

  def update_tags
  	thread = EmailThread.where(synced: true).find_by(id: params['thread_id'])
    if !thread.nil? and User.can_access_thread(thread.id, current_user.id)
  		if params[:tag_type] == 'highlight'
        if params[:tag_highlight] # Thread to be highlighted
    			thread.set_highlight(true)
    		else
    			thread.set_highlight(false)
    		end
      elsif params[:tag_type] == 'hide'
        if params[:tag_hide] # Thread to be hidden
          thread.set_hidden(true)
        else
          thread.set_hidden(false)
        end
      end
  	end
  	respond_to do |format|
      format.js
    end
  end
end
