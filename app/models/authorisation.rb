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
					email_thread = self.email_threads.find_by(threadId: thread['id'])
					t = self.email_threads.create(
						threadId: thread['id'],
						snippet: thread['snippet'],
						historyId: thread['historyId']) unless !email_thread.nil?
				end
			end
		end

		# Grab all threads from DB and add messages that don't exist yet (and their attachments)
		self.email_threads.all.each do |thread|
			# Grab all messages in that thread
			messages = client.get_thread(thread.threadId)
			ActiveRecord::Base.transaction do
				messages['messages'].each do |message|
					message_db = self.email_messages.find_by(messageId: message['id'])
					# Process the message only if it's not in the DB yet
					if message_db.nil?
						# The data we're trying to find
						email_message = {
							email_thread_id: thread.id,
							messageId: message['id'],
							snippet: message['snippet'],
							historyId: message['historyId'],
							internalDate: message['internalDate'],
							body_text: '',
							body_html: '',
							sizeEstimate: message['sizeEstimate'],
							mimeType: message['payload']['mimeType'],
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
						message['payload']['headers'].each do |header|
							case header['name']
							when 'Subject'
								email_message[:subject] = header['value']
							#TODO: add participants logic here
							end
						end
						
						# Save the message itself and attachments if any
						e = EmailMessage.create(email_message)
						attachments.each do |attachment|
							e.message_attachments.create(attachment)
						end
					end
				end
			end
		end
		self.update!(synced: true)
	end

	# Analyses an email message part and returns nil if it's not a attachment, or a hash with the attachment data
	def process_attachment(message_part)
		if ['text/plain', 'text/html', 'multipart/alternative'].include?(message_part['mimeType'])
			nil
		else
			attachment = {
				mimeType: message_part['mimeType'],
				filename: message_part['filename'],
				attachmentId: message_part['body']['attachmentId'],
				size: message_part['body']['size'],
				inline: false
			}
			message_part['headers'].each do |header|
				case header['name']
				when 'Content-Disposition'
					attachment[:inline] = true unless header['value'].index('inline').nil?
				end
			end
			attachment
		end
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
