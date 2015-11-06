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

  desc "Destroy everything belonging to an authorisation and try re-syncing again"
  # Call with e.g rake testing:resync_authorisation\[4\] when using ZSH
  task :resync_authorisation, [:authorisation_id] => :environment do |task, args|
    auth = Authorisation.find_by(id: args.authorisation_id)
    if !auth.nil?
      auth.email_threads.destroy_all
      auth.email_messages.destroy_all
      auth.message_attachments.destroy_all
      auth.message_participants.destroy_all
      auth.update(synced: false)
      auth.sync_gmail
    end
  end
end