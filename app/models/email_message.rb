class EmailMessage < ActiveRecord::Base
  belongs_to :email_thread
  has_many :email_headers
  has_many :message_attachments

  def subject
  	self.email_headers.where(name: 'Subject').first.value
  end

  # Returns a decoded plain text body (use simple_format xxx in the view)
  def body_text
  	Base64.urlsafe_decode64(super)
  end

  # Returns a decoded html body
  def body_html
  	Base64.urlsafe_decode64(super).html_safe
  end
end
