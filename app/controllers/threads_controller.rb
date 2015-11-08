class ThreadsController < ApplicationController
  before_action :logged_in_user

  layout 'stripped'

  def show
  	@thread = current_user.email_threads.where(synced: true).find_by(id: params['id'])
  	if !@thread.nil?
	  	@emails = @thread.email_messages.includes(:message_attachments, :message_participants, :participants) # TODO: change to download emails from Gmail
	 end
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
