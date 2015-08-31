class Authorisation < ActiveRecord::Base
	belongs_to :requester, class_name: 'User'
	belongs_to :granter, class_name: 'User'
	validates :requester_id, presence: true
	validates :granter_id, presence: true
	validates :scope, presence: true
	has_many :email_threads
	has_many :email_messages, through: :email_threads
	has_many :email_headers, through: :email_messages
	has_many :message_attachments, through: :email_messages
	has_many :attachment_headers, through: :message_attachments
  	scope :authorised,  -> { where(:enabled => true) }
  	scope :uptodate,  -> { where(:synced => true) } # initial sync has been done

	after_update :sync_job, :if => :enabled_changed?

	def sync_job
		GmailSyncerJob.new.async.perform(self)
	end

	def sync_gmail
		return false unless self.enabled # only enabled authorisations can be synced

		client = Gmail.new(self.granter.tokens.last.fresh_token)
		thread_pages = client.list_threads(self.scope)
		
		ActiveRecord::Base.transaction do
			require 'pp'
			# Grab all pages of threads
			thread_pages.each do |threads|
				# Grab all threads
				threads['threads'].each do |thread|
					t = self.email_threads.create(
						threadId: thread['id'],
						snippet: thread['snippet'],
						historyId: thread['historyId'])
					
					# Grab all messages in that thread
					messages = client.get_thread(thread['id'])
					messages['messages'].each do |message|
						
						pp message
						# Find the body depending on the mimeType
						body_text = ''
						body_html = ''
						if message['payload']['mimeType'] == 'text/plain' or message['payload']['parts'].nil?
							body_text = message['payload']['body']['data']
						else
							message['payload']['parts'].each do |part|
								if part['mimeType'] == 'text/plain'
									body_text = part['body']['data']
								elsif part['mimeType'] == 'text/html'
									body_html = part['body']['data']
								elsif part['mimeType'] == 'multipart/alternative'
									part['parts'].each do |subpart|
										if subpart['mimeType'] == 'text/plain'
											body_text = subpart['body']['data']
										elsif subpart['mimeType'] == 'text/html'
											body_html = subpart['body']['data']
										end
									end
								end
							end
						end
						
						# Save the message itself
						e = t.email_messages.create(
							messageId: message['id'],
							snippet: message['snippet'],
							historyId: message['historyId'],
							internalDate: message['internalDate'],
							body_text: body_text,
							body_html: body_html,
							sizeEstimate: message['sizeEstimate'],
							mimeType: message['payload']['mimeType']
							)
						
						# Grab all headers for that message
						message['payload']['headers'].each do |header|
							e.email_headers.create(
								name: header['name'],
								value: header['value'])
						end

						# Find if there are attachments and save them (without the files themselves)
						if message['payload']['mimeType'] == 'multipart/mixed'
							message['payload']['parts'].each do |part|
								if part['mimeType'] != 'text/plain' and part['mimeType'] != 'text/html' and part['mimeType'] != 'multipart/alternative'
									a = e.message_attachments.create(
										mimeType: part['mimeType'],
										filename: part['filename'],
										attachmentId: part['body']['attachmentId'],
										size: part['body']['size'])
									part['headers'].each do |header|
										a.attachment_headers.create(
											name: header['name'],
											value: header['value'])
									end
								end
							end
						end
					end
				end
			end
			self.update!(synced: true)
		end
	end
end
