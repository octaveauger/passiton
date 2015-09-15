class MessageAttachment < ActiveRecord::Base
  belongs_to :email_message

  def download
  	client = Gmail.new(self.email_message.email_thread.authorisation.granter.tokens.last.fresh_token)
	attachment = client.download_attachment(self.email_message.messageId, self.attachmentId)
	if attachment['data'].nil?
		false
	else
		save_file(Base64.urlsafe_decode64(attachment['data']))
		true
	end
  end

  def save_file(attachment_content)
  	File.open("app/assets/images/"+self.filename, 'wb') do |f|
  		f.write(attachment_content)
  	end
  end
end
