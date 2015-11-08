class GmailSyncerJob 
  include SuckerPunch::Job
  workers 2
  
  def perform(authorisation, first_time = false, user = 'requester')
    ActiveRecord::Base.connection_pool.with_connection do
    	GmailSync.prep_sync(authorisation)
    	if first_time
    		AuthorisationMailer.request_authorisation(authorisation).deliver if user == 'requester'
    		AuthorisationMailer.authorisation_granted(authorisation).deliver if user == 'granter'
    	end
    end
  end
end
