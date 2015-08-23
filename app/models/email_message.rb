class EmailMessage < ActiveRecord::Base
  belongs_to :email_thread
  has_many :email_headers
  has_many :message_attachments
end
