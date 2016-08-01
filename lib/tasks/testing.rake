namespace :testing do

  desc "Empty the whole database apart from Users"
  task empty_db: :environment do
  	Authorisation.delete_all
  	EmailThread.delete_all
  	MessageAttachment.delete_all
  	MessageParticipant.delete_all
  	Participant.delete_all
    Tag.delete_all
    Label.delete_all
    Delegation.delete_all
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
      auth.message_attachments.destroy_all
      auth.message_participants.destroy_all
      auth.update(synced: false)
      auth.sync_gmail
    end
  end

  desc "Fill token for all existing authorisations following their tokenisation DB migration"
  task tokenise_authorisations: :environment do
    Authorisation.where(token: nil).all.each do |auth|
      token = loop do
        random_token = SecureRandom.urlsafe_base64(nil, false)
        break random_token unless Authorisation.exists?(token: random_token)
      end
      auth.update!(token: token)
    end
  end

  desc "Make everyone a manager"
  task make_everyone_manager: :environment do
    User.where(guest: false).each do |user| # only for non guest accounts
      user.update(is_manager: true)
    end
  end

end