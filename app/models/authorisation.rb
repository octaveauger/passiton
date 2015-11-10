include ApplicationHelper
include ThreadHelper

class Authorisation < ActiveRecord::Base
	belongs_to :requester, class_name: 'User'
	belongs_to :granter, class_name: 'User'
	validates :requester_id, presence: true
	validates :granter_id, presence: true
	validates :scope, presence: true
	validates :status, presence: true, inclusion: { in: ['pending', 'granted', 'denied', 'revoked'] }
	attr_accessor :granter_email
	has_many :email_threads
	has_many :message_attachments, through: :email_threads
	has_many :message_participants, through: :email_threads
	has_many :participants, through: :message_participants
	has_many :synchronisation_errors
  	scope :authorised,  -> { where(:status => 'granted') }
  	scope :uptodate,  -> { where(:synced => true) } # initial sync has been done

	# Launches an asynchronous sync of threads etc. (first_time = true if this is the first sync)
	def sync_job(first_time = false, user = 'requester')
		GmailSyncerJob.new.async.perform(self, first_time, user)
	end

	def enabled
		self.status == 'granted'
	end

	# Returns the different statuses the authorisation can move to
	def possible_statuses
		case self.status
		when 'pending'
			['granted', 'denied']
		when 'granted'
			['revoked']
		when 'denied'
			['granted']
		when 'revoked'
			['granted']
		else
			[]
		end
	end

	def update_status(status)
		self.update!(status: status)
		case self.status
		when 'granted'
			if !self.synced
				self.sync_job(true, 'granter')
			else
				AuthorisationMailer.authorisation_granted(self).deliver
			end
		when 'denied'
			AuthorisationMailer.authorisation_denied(self).deliver
		when 'revoked'
			AuthorisationMailer.authorisation_revoked(self).deliver
		end
	end
end
