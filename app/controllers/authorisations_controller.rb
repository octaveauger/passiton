class AuthorisationsController < ApplicationController
  def index
  	@authorisations = current_user.requested_authorisations.all
  end

  def show
  	@authorisation = current_user.requested_authorisations.find(params[:id])
  	if @authorisation.nil?
  		flash[:alert] = "This page wasn't found"
  		redirect to authorisations_path
  	end
  	@threads = @authorisation.email_threads.includes(:email_messages, :email_headers, :message_attachments, :attachment_headers).all
  end
end
