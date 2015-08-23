class EmailThread < ActiveRecord::Base
	belongs_to :authorisation
	has_many :email_messages
	has_many :email_headers, through: :email_messages
	has_many :message_attachments, through: :email_messages
	has_many :attachment_headers, through: :message_attachments
end
