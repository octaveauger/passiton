namespace :gmail_syncing do
  desc "Synchronises all authorisations that are enabled on a regular basis"
  task sync_all: :environment do
  	User.where(guest: false) do |user|
  		ContinuousGmailSyncJob.new.async.perform(user)
  	end
  end

  desc "Adds the latest email date to existing threads"
  task upgrade_latest_email_date: :environment do
  	EmailThread.all do |thread|
  		thread.update(latest_email_date: thread.last_email_date)
  	end
  end

end
