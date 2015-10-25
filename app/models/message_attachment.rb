class MessageAttachment < ActiveRecord::Base
  belongs_to :email_message
  mount_uploader :file, AttachmentUploader

  def download
  	client = Gmail.new(self.email_message.email_thread.authorisation.granter.tokens.last.fresh_token)
  	attachment = client.download_attachment(self.email_message.message_id, self.attachment_id)
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

  def glyphicon
    if %w(PNG GIF JPG).include? self.type
      'glyphicon glyphicon-picture'
    elsif self.type == 'ICS'
      'glyphicon glyphicon-calendar'
    elsif %w(DOC DOCX PDF XLS).include? self.type
      'glyphicon glyphicon-list-alt'
    elsif self.type == 'ZIP'
      'glyphicon glyphicon-folder-close'
    else
      'glyphicon glyphicon-file'
    end
  end

  def self.not_inline
    self.where(inline: false)
  end
end
