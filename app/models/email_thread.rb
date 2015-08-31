include ThreadHelper

class EmailThread < ActiveRecord::Base
	belongs_to :authorisation
	has_many :email_messages
	has_many :email_headers, through: :email_messages
	has_many :message_attachments, through: :email_messages
	has_many :attachment_headers, through: :message_attachments

	# Returns an array of hashes with the name, email and domain of all participants to a thread
	# e.g participants.each do |p|
	# 		  p[:name] #or p[:email] p[:domain]
	#     end
	def participants
		participants = []
		self.email_headers.where('name = ? or name = ? or name = ? or name = ? or name = ?', 'To', 'Cc', 'Bcc', 'From', 'Delivered-To').each do |header|
			explode_emails(header.value).each do |email|
				email = parse_email(email)
				participants.push(email) unless
				(participants.any? { |h| h[:email] == email[:email] } or !email[:email].index('emailtosalesforce').nil? )
			end
		end
		participants
	end

	# Returns the subject line of a thread
	def subject
		self.email_messages.order('internalDate asc').first.subject
	end

	# Returns the datetime of the first email in the thread
	def first_email_date
		Time.at((self.email_messages.order('internalDate asc').first.internalDate/1000).to_i).utc.to_datetime
	end

	# Returns the datetime of the last email in the thread
	def last_email_date
		Time.at((self.email_messages.order('internalDate desc').first.internalDate/1000).to_i).utc.to_datetime
	end

end
