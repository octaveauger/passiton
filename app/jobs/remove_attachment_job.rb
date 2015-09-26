class RemoveAttachmentJob 
  include SuckerPunch::Job
  workers 2
  
  def perform(attachment_id)
    ActiveRecord::Base.connection_pool.with_connection do
    	attachment = MessageAttachment.find(attachment_id)
    	attachment.remove_file!
    	attachment.save
    end
  end

  def later(sec, attachment_id)
    after(sec) { perform(attachment_id) }
  end
end
