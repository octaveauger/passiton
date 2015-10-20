class ThreadsController < ApplicationController
  before_action :logged_in_user

  layout 'stripped'

  def show
  	@thread = current_user.email_threads.where(synced: true).find_by(id: params['id'])
  	if !@thread.nil?
	  	@emails = @thread.email_messages.includes(:message_attachments, :message_participants, :participants)
	end
  end
end
