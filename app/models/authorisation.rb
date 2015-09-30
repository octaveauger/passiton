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
	has_many :email_messages, through: :email_threads
	has_many :message_attachments, through: :email_messages
	has_many :message_participants, through: :email_messages
	has_many :participants, through: :message_participants
  	scope :authorised,  -> { where(:status => 'granted') }
  	scope :uptodate,  -> { where(:synced => true) } # initial sync has been done

	def sync_job
		GmailSyncerJob.new.async.perform(self)
	end

	def sync_gmail
		return false unless self.enabled # only enabled authorisations can be synced

		client = Gmail.new(self.granter.tokens.last.fresh_token)
		thread_pages = client.list_threads(self.scope)
		
		ActiveRecord::Base.transaction do
			# Grab all pages of threads
			thread_pages.each do |threads|
				# Grab all threads from Gmail and save the ones that don't exist in the DB
				threads['threads'].each do |thread|
					email_thread = self.email_threads.find_by(thread_id: thread['id'])
					t = self.email_threads.create(
						thread_id: thread['id'],
						snippet: thread['snippet'],
						history_id: thread['historyId'],
						synced: false) unless !email_thread.nil?
				end
			end
		end

		# Grab all threads from DB and add messages that don't exist yet (and their attachments)
		self.email_threads.all.each do |thread|
			thread.update(synced: false) unless !thread.synced
			# Grab all messages in that thread
			messages = client.get_thread(thread.thread_id)
			messages['messages'].each do |message|
				begin
					message_db = self.email_messages.find_by(message_id: message['id'])
					# Process the message only if it's not in the DB yet
					if message_db.nil?
						# The data we're trying to find
						email_message = {
							email_thread_id: thread.id,
							message_id: message['id'],
							snippet: message['snippet'],
							history_id: message['historyId'],
							internal_date: message['internalDate'],
							body_text: '',
							body_html: '',
							size_estimate: message['sizeEstimate'],
							mime_type: message['payload']['mimeType'],
							subject: ''
						}
						attachments = []
						
						# Find the body depending on the mimeType and process attachments
						if message['payload']['mimeType'] == 'text/plain' or message['payload']['parts'].nil?
							email_message[:body_text] = message['payload']['body']['data']
						else
							message['payload']['parts'].each do |part|
								if part['mimeType'] == 'text/plain'
									email_message[:body_text] = part['body']['data']
								elsif part['mimeType'] == 'text/html'
									email_message[:body_html] = part['body']['data']
								else
									part_attachment = self.process_attachment(part)
									attachments.push(part_attachment) unless part_attachment.nil?
								end
								
								if !part['parts'].nil? # go through parts if any
									part['parts'].each do |subpart|
										if subpart['mimeType'] == 'text/plain'
											email_message[:body_text] = subpart['body']['data']
										elsif subpart['mimeType'] == 'text/html'
											email_message[:body_html] = subpart['body']['data']
										else
											subpart_attachment = self.process_attachment(subpart)
											attachments.push(subpart_attachment) unless subpart_attachment.nil?
										end

										if !subpart['parts'].nil?
											subpart['parts'].each do |subsubpart| # go through parts if any
												if subsubpart['mimeType'] == 'text/plain'
													email_message[:body_text] = subsubpart['body']['data']
												elsif subsubpart['mimeType'] == 'text/html'
													email_message[:body_html] = subsubpart['body']['data']
												else
													subsubpart_attachment = self.process_attachment(subsubpart)
													attachments.push(subsubpart_attachment) unless subsubpart_attachment.nil?
												end
											end
										end
									end
								end
							end
						end

						# Extract all interesting data from the headers for that message
						participants = []
						message['payload']['headers'].each do |header|
							if header['name'] == 'Subject'
								email_message[:subject] = header['value']
							elsif ['To', 'Cc', 'Bcc', 'From'].include?(header['name'])
								participants += self.process_participants(header['name'], header['value'])
							end
						end
						
						# Save the message itself and attachments and participants if any
						e = EmailMessage.create!(email_message)
						attachments.each do |attachment|
							attachment_db = e.message_attachments.create!(attachment)
							# Asynchronously download the file if it's inline
							if Rails.env.production?
								AttachmentDownloadJob.new.async.perform(attachment_db) if attachment[:inline] #asynchronous only on postgres who can handle it
							else
								attachment_db.download if attachment[:inline]
							end
						end
						participants.each do |participant|
							participant_db = Participant.find_by(email: participant[:email])
							if participant_db.nil? # Just create the participant
								participant_db = Participant.create(
									first_name: participant[:first_name],
									last_name: participant[:last_name],
									email: participant[:email],
									domain: participant[:domain],
									company: participant[:company]
								)
							else # Update the participant if we now have more information about them
								if participant[:first_name] != '' and participant_db.first_name == ''
									participant_db.update(
										first_name: participant[:first_name],
										last_name: participant[:last_name],
									)
								end
							end
							MessageParticipant.create(
								email_message_id: e.id,
								participant_id: participant_db.id,
								delivery: participant[:delivery]
							)
						end
					end
				rescue => e
					Utility.log_exception(e, { user: self.requester.id, authorisation: self.id, message: message })
					return false
			    end
			thread.update(synced: true)
			end
		end
		self.update!(synced: true)
	end

	# Analyses an email message part and returns nil if it's not a attachment, or a hash with the attachment data
	def process_attachment(message_part)
		if ['text/plain', 'text/html', 'multipart/alternative', 'multipart/related'].include?(message_part['mimeType'])
			nil
		else
			attachment = {
				mime_type: message_part['mimeType'],
				filename: message_part['filename'],
				attachment_id: message_part['body']['attachmentId'],
				size: message_part['body']['size'],
				content_id: '',
				inline: false
			}
			message_part['headers'].each do |header|
				case header['name']
				when 'Content-Disposition' # If contains "inline", then it's inline
					attachment[:inline] = true unless header['value'].index('inline').nil?
				when 'X-Attachment-Id' # Indicates the position of the inline attachment
					attachment[:content_id] = header['value']
				end
			end
			attachment
		end
	end

	def process_participants(delivery, raw_participants)
		participants = []
		delivery.downcase!
		explode_emails(raw_participants).each do |email|
			email = parse_email(email)
			email[:delivery] = delivery
			participants.push(email) unless ( participants.any? { |h| h[:email] == email[:email] } or !email[:email].index('emailtosalesforce').nil? )
		end
		participants
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
			self.sync_job
			AuthorisationMailer.authorisation_granted(self).deliver
		when 'denied'
			AuthorisationMailer.authorisation_denied(self).deliver
		when 'revoked'
			AuthorisationMailer.authorisation_revoked(self).deliver
		end
	end
end
