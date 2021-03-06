class MessageAttachment < ActiveRecord::Base
  belongs_to :email_thread
  mount_uploader :file, AttachmentUploader

  def download
  	begin
      client = Gmail.new(self.email_thread.authorisation.granter.tokens.last.fresh_token, self.email_thread.authorisation.granter.email)
    rescue => e
      authorisation.granter.register_oauth_cancelled
      return false
    end

    attachment = client.download_attachment(self.email_message_id, self.attachment_id)
  	if attachment['data'].nil?
  		false
  	else
  		file = AppSpecificStringIO.new(self.filename, Base64.urlsafe_decode64(attachment['data']))
      self.update!(file: file)
  		true
  	end
  end

  def type
    extension = File.extname(self.filename)
    extension[0] = ''
    extension.upcase
  end

  def type_group
    if %w(DOC DOCX PDF XLS CSV XLSX ZIP PPT PPTX KEY).include? type
      'Documents'
    elsif %w(PNG GIF JPG JPEG).include? type
      'Images'
    elsif type == 'ICS'
      'Invites'
    else
      'Others'
    end
  end

  def self.is_inline
    self.where(inline: true)
  end

  def self.not_inline
    self.where(inline: false)
  end

  # Returns message attachments for a given email message
  def self.find_for_message(message_id)
    self.where('email_message_id = ?', message_id)
  end

  # Returns the participant who sent that attachment
  def participant_sender
    message_participant = MessageParticipant.where(delivery: 'from').where(email_message_id: self.email_message_id).first
    message_participant.nil? ? nil : message_participant.participant
  end
end
