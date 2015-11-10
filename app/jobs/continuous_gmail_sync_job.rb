class ContinuousGmailSyncJob 
  include SuckerPunch::Job
  workers 2
  
  def perform(user)
    ActiveRecord::Base.connection_pool.with_connection do
	    user.requested_authorisations.where(status: 'granted').each do |authorisation|
	    	GmailSync.prep_sync(authorisation)
	    end
	end
  end
end
