class AuthorisationRevokerJob 
  include SuckerPunch::Job
  workers 2
  
  # When an authorisation is revoked, remove all of the downloaded content from the DB but keep the authorisation itself
  def perform(authorisation)
    ActiveRecord::Base.connection_pool.with_connection do
    	authorisation.authorisation_searches.destroy_all
      authorisation.email_threads.destroy_all
      authorisation.update(synced: false)
    end
  end
end
