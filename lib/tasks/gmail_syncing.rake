namespace :gmail_syncing do
  desc "Synchronises all authorisations that are enabled on a regular basis"
  task sync_all: :environment do
  	User.where(guest: false) do |user|
  		ContinuousGmailSyncJob.new.async.perform(user)
  	end
  end

  desc "Updates tags to existing threads"
  task update_all_tags: :environment do
    EmailThread.all do |thread|
      thread.update_tags
    end
  end

end
