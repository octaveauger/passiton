namespace :testing do

  desc "Empty the whole database apart from Users"
  task empty_db: :environment do
  	Authorisation.destroy_all
  	EmailThread.destroy_all
  	EmailMessage.destroy_all
  	MessageAttachment.destroy_all
  	MessageParticipant.destroy_all
  	Participant.destroy_all
    Tag.destroy_all
    Label.destroy_all
  end

  desc "Update tags for all threads"
  task update_all_tags: :environment do
  	EmailThread.all.each do |thread|
  		thread.update_tags if !thread.participants.empty?
  	end
  end
end