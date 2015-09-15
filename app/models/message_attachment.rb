class MessageAttachment < ActiveRecord::Base
  belongs_to :email_message
  mount_uploader :file, AttachmentUploader

  def download
  	client = Gmail.new(self.email_message.email_thread.authorisation.granter.tokens.last.fresh_token)
  	attachment = client.download_attachment(self.email_message.messageId, self.attachmentId)
  	if attachment['data'].nil?
  		false
  	else
  		file = AppSpecificStringIO.new(self.filename, Base64.urlsafe_decode64(attachment['data']))
      self.update!(file: file)
  		true
  	end
  end
end
