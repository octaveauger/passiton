namespace :testing do

  desc "Empty the whole database apart from Users"
  task empty_db: :environment do
  	Authorisation.destroy_all
  	EmailThread.destroy_all
  	EmailMessage.destroy_all
  	EmailHeader.destroy_all
  	MessageAttachment.destroy_all
  	AttachmentHeader.destroy_all
  end
end