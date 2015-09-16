class AttachmentDownloadJob 
  include SuckerPunch::Job
  workers 2
  
  def perform(message_attachment)
    ActiveRecord::Base.connection_pool.with_connection do
    	message_attachment.download
    end
  end
end
