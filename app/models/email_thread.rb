class EmailThread < ActiveRecord::Base
	belongs_to :authorisation
	has_many :email_messages
	has_many :email_headers, through: :email_messages
	has_many :message_attachments, through: :email_messages
	has_many :attachment_headers, through: :message_attachments

	def participants
		participants = []
		self.email_headers.where('name = ? or name = ? or name = ?', 'To', 'Cc', 'Bcc').each do |header|
			participants.push(header.value) unless participants.include? header.value
		end
		participants
	end
end
