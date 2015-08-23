namespace :testing do

  desc "Empty the whole database apart from Users and Authorisations"
  task empty_db: :environment do
  	EmailThread.destroy_all
  	EmailMessage.destroy_all
  	EmailHeader.destroy_all
  	MessageAttachment.destroy_all
  	AttachmentHeader.destroy_all
  end
end