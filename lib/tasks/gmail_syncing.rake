namespace :gmail_syncing do
  desc "Synchronises all authorisations that are enabled on a regular basis"
  task sync_all: :environment do
  	User.where(guest: false) do |user|
  		ContinuousGmailSyncJob.new.async.perform(user)
  	end
  end

end
