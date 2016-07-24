class AttachmentController < ApplicationController
  before_action :logged_in_user

  def show
  	@attachment = MessageAttachment.find_by(id: params[:id])
  	if @attachment.nil? or !User.can_access_authorisation(@attachment.email_thread.authorisation.id, current_user.id) or !@attachment.email_thread.authorisation.enabled
  		flash[:alert] = "This attachment doesn't exist or you don't have access to it"
  		redirect_to authorisations_path and return
  	end

  	# Download from Gmail and store
  	@attachment.download unless !@attachment.file.url.nil?
  	# Remove in 60min
  	RemoveAttachmentJob.new.async.later(3600, @attachment.id)
  	# Return the file
  	if Rails.env.production?
      redirect_to @attachment.file.url and return
    else
      send_file File.join('public', @attachment.file.url), type: @attachment.mime_type, x_sendfile: true
    end
  end

  def download_inline
    @attachment = MessageAttachment.find_by(content_id: params[:content_id], email_thread_id: params[:email_thread_id])
    if !@attachment.nil? and User.can_access_authorisation(attachment.email_thread.authorisation.id, current_user.id) and @attachment.email_thread.authorisation.enabled
      @attachment.download unless !@attachment.file.url.nil? # Download from Gmail and store
      respond_to do |format|
        format.js
      end
    end
  end
end
