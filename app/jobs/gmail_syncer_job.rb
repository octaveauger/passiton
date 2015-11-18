class GmailSyncerJob 
  include SuckerPunch::Job
  workers 2
  
  def perform(authorisation, first_time = false, user = 'requester')
    ActiveRecord::Base.connection_pool.with_connection do
    	Rails.logger.info('Gmail Syncer Job started for scope: ' + authorisation.scope + ' and id: ' + authorisation.id.to_s)
      GmailSync.prep_sync(authorisation)
      Rails.logger.info('Gmail Syncer Job completed for scope: ' + authorisation.scope + ' and id: ' + authorisation.id.to_s)
    	if first_time
    		AuthorisationMailer.request_authorisation(authorisation).deliver if user == 'requester'
    		AuthorisationMailer.authorisation_granted(authorisation).deliver if user == 'granter'
    	end
    end
  end
end
