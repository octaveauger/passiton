include ThreadHelper

class EmailThread < ActiveRecord::Base
	belongs_to :authorisation
	has_many :email_messages
	has_many :message_attachments, through: :email_messages
	has_many :message_participants, through: :email_messages
	has_many :participants, through: :message_participants

	# Returns the subject line of a thread
	def subject
		self.email_messages.order('internalDate asc').first.subject
	end

	# Returns the datetime of the first email in the thread
	def first_email_date
		Time.at((self.email_messages.order('internalDate asc').first.internalDate.to_i/1000).to_i).utc.to_datetime
	end

	# Returns the datetime of the last email in the thread
	def last_email_date
		Time.at((self.email_messages.order('internalDate desc').first.internalDate.to_i/1000).to_i).utc.to_datetime
	end

	def participants
		super.uniq
	end

end
