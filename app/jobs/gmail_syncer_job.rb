class GmailSyncerJob 
  include SuckerPunch::Job
  workers 2
  
  def perform(authorisation)
    ActiveRecord::Base.connection_pool.with_connection do
    	authorisation.sync_gmail
    end
  end
end
