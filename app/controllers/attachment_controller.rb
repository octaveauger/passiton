class AttachmentController < ApplicationController
  before_action :logged_in_user

  def show
  	@attachment = current_user.message_attachments.find_by(id: params[:id])
  	if @attachment.nil? or !@attachment.email_message.email_thread.authorisation.enabled
  		flash[:alert] = "This attachment doesn't exist or you don't have access to it"
  		redirect_to authorisations_path
  	end

  	# Download from Gmail and store
  	@attachment.download unless !@attachment.file.url.nil?
  	# Remove in 60min
  	RemoveAttachmentJob.new.async.later(3600, @attachment.id)
  	# Return the file
  	send_file File.join('public',@attachment.file.url), type: @attachment.mimeType, x_sendfile: true
  end
end
