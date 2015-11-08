class GmailSync
	# Synchronises everything except the email messages
	def self.prep_sync(authorisation)
		client = Gmail.new(authorisation.granter.tokens.last.fresh_token)
		
		# Sync threads
		self.sync_threads(authorisation)
		threads = authorisation.email_threads.all

		# Get current list of Participants
		participants_db = Participant.all
		participants_scope = [] # will contain all new participants we add here

		# Find the latest labels that the granter has in Gmail
		Label.sync_gmail(authorisation.granter) # Create or update the list of labels of the granter
		user_labels = Label.to_array(authorisation.granter)
		
		# Loop through threads
		threads.each do |thread|
			thread.update(synced: false) unless !thread.synced
			
			email_count = 0
			subject = thread.subject.to_s
			thread_labels = []
			earliest_email_date = thread.earliest_email_date
			latest_email_date = thread.latest_email_date

			# Get messages for the thread
			messages = client.get_thread(thread.thread_id)

			# Go through each message and prepare what needs to be stored in the DB
			messages['messages'].each do |message|
				begin
					email_count += 1
					subject = (message['payload']['headers'].detect { |h| h['name'] == 'Subject' })['value'].to_s if subject.blank?

					# Find the attachments
					attachments = self.analyse_message_attachments(message)
					attachments.each do |attachment|
						attachment_db = thread.message_attachments.create!(attachment)
						# Asynchronously download the file if it's inline / TODO: decide when to handle the download of inline attachments
					#	if Rails.env.production?
					#		AttachmentDownloadJob.new.async.perform(attachment_db) if attachment[:inline] #asynchronous only on postgres who can handle it
					#	else
					#		attachment_db.download if attachment[:inline]
					#	end
					end

					# Add the labels if they're not included yet
					message['labelIds'].each do |label|
						thread_labels.push(label) unless thread_labels.include? label or !user_labels.include? label
					end

					# Find participants
					participants_scope += self.analyse_message_participants(message['id'], thread.id, message['payload']['headers'], participants_db, participants_scope)
					
					# Check if the date of the email is later than the latest date (same for earliest) for the thread
					email_date = Time.at((message['internalDate'].to_i/1000).to_i).utc.to_datetime
					earliest_email_date = email_date if earliest_email_date.nil? or email_date < earliest_email_date
					latest_email_date = email_date if latest_email_date.nil? or email_date > latest_email_date
				rescue => e
					Utility.log_exception(e, { user: authorisation.requester.id, authorisation: authorisation.id, message: message })
					authorisation.synchronisation_errors.create(content: message.to_json)
					return false
			    end
			end # end loop messages
			thread.update(
				email_count: email_count,
				subject: subject,
				labels: thread_labels.to_json,
				earliest_email_date: earliest_email_date,
				latest_email_date: latest_email_date,
				synced: true
			)
			thread.update_tags
		end # end loop threads
		authorisation.update(synced: true) if !authorisation.synced
	end

	# Ensures the authorisation has an up-to-date list of email_threads in the DB
	def self.sync_threads(authorisation)
		client = Gmail.new(authorisation.granter.tokens.last.fresh_token)

		thread_db = authorisation.email_threads.all
		threads = client.list_threads(authorisation.scope)
		# Grab all threads from Gmail and save them if they don't exist in the DB yet
		threads.each do |thread|
			begin
				if !(thread_db.any? { |t| t.thread_id == thread['id'] })
					authorisation.email_threads.create(
						thread_id: thread['id'],
						snippet: thread['snippet'],
						history_id: thread['historyId'],
						synced: false
					)
				end
			rescue => e
				Utility.log_exception(e, { user: authorisation.requester.id, authorisation: authorisation.id })
				authorisation.synchronisation_errors.create(content: threads.to_json)
		    end
		end
	end

	# Retrieves email messages from Gmail for a given thread and returns an array of EmailMessage
	def self.get_emails(authorisation, thread_id)
		client = Gmail.new(authorisation.granter.tokens.last.fresh_token)
		
		messages = client.get_thread(thread_id) # messages are returned in an ascending by internalDate order (i.e latest email is last)
		results = []
		
		messages['messages'].each do |message|
			email_message = self.analyse_message_content(message) # extract all that's needed from the message
			results.push(EmailMessage.new(email_message)) # add the EmailMessage to the results array
		end # end loop messages
		results
	end

	# Handles participants for a message
	# Input: the message header, the list of all participants in the DB, an array of participants already found by this method for other emails
	# Output: an array of Participants
	def self.analyse_message_participants(message_id, thread_id, message_headers, participants_from_db, participants_found)
		participants = []
		participants_created = []
		message_headers.each do |header|
			if ['To', 'Cc', 'Bcc', 'From'].include?(header['name'])
				participants += self.process_participants(header['name'], header['value'])
			end
		end
		participants.each do |participant|
			participant_db = participants_found.detect { |p| p.email == participant[:email] } # search in the recently created participants first
			participant_db = participants_from_db.detect { |p| p.email == participant[:email] } if participant_db.nil? # search in DB if it's not in the recently created participants
			if participant_db.nil? # Just create the participant
				participant_db = Participant.create(
					first_name: participant[:first_name],
					last_name: participant[:last_name],
					email: participant[:email],
					domain: participant[:domain],
					company: participant[:company]
				)
				participants_created.push(participant_db) # we add it to the output of this method
			else # Update the participant if we now have more information about them
				if participant[:first_name] != '' and participant_db.first_name == ''
					participant_db.update(
						first_name: participant[:first_name],
						last_name: participant[:last_name],
					)
				end
			end
			MessageParticipant.create(
				email_message_id: message_id,
				email_thread_id: thread_id,
				participant_id: participant_db.id,
				delivery: participant[:delivery]
			)
		end
		participants_created
	end

	def self.process_participants(delivery, raw_participants)
		participants = []
		delivery.downcase!
		explode_emails(raw_participants).each do |email|
			email = parse_email(email)
			email[:delivery] = delivery
			participants.push(email) unless ( participants.any? { |h| h[:email] == email[:email] } or !email[:email].index('emailtosalesforce').nil? )
		end
		participants
	end

	# Extract the email_message attachments
	def self.analyse_message_attachments(message)
		attachments = []
		
		# Find the body depending on the mimeType and process attachments
		if !(message['payload']['mimeType'] == 'text/plain' or message['payload']['parts'].nil?)
			message['payload']['parts'].each do |part|
				if !['text/plain', 'text/html'].include? part['mimeType']
					part_attachment = self.process_attachment(message, part, message['id'])
					attachments.push(part_attachment) unless part_attachment.nil?
				end
				
				if !part['parts'].nil? # go through parts if any
					part['parts'].each do |subpart|
						if !['text/plain', 'text/html'].include? subpart['mimeType']
							subpart_attachment = self.process_attachment(message, subpart, message['id'])
							attachments.push(subpart_attachment) unless subpart_attachment.nil?
						end

						if !subpart['parts'].nil?
							subpart['parts'].each do |subsubpart| # go through parts if any
								if !['text/plain', 'text/html'].include? subsubpart['mimeType']
									subsubpart_attachment = self.process_attachment(message, subsubpart, message['id'])
									attachments.push(subsubpart_attachment) unless subsubpart_attachment.nil?
								end
							end
						end
					end
				end
			end
		end
		attachments
	end

	# Analyses an email message part and returns nil if it's not a attachment, or a hash with the attachment data
	def self.process_attachment(message, message_part, message_id)
		if ['text/plain', 'text/html', 'multipart/alternative', 'multipart/related'].include?(message_part['mimeType'])
			nil
		else
			attachment = {
				email_message_id: message_id,
				email_date: Time.at((message['internalDate'].to_i/1000).to_i).utc.to_datetime,
				mime_type: message_part['mimeType'],
				filename: message_part['filename'],
				attachment_id: message_part['body']['attachmentId'],
				size: message_part['body']['size'],
				content_id: '',
				inline: false
			}
			return nil if message_part['headers'].nil? # To make sure if there's a new type of mimeType that's not an attachment, it doesn't crash
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

	# Extract the email_message content
	def self.analyse_message_content(message)
		# The data we're trying to find
		email_message = {
			email_thread_id: message['threadId'],
			message_id: message['id'],
			snippet: message['snippet'],
			history_id: message['historyId'],
			internal_date: message['internalDate'],
			body_text_raw: '',
			body_html_raw: '',
			size_estimate: message['sizeEstimate'],
			mime_type: message['payload']['mimeType'],
			subject: ''
		}
		
		# Find the body depending on the mimeType and process attachments
		if message['payload']['mimeType'] == 'text/plain' or message['payload']['parts'].nil?
			email_message[:body_text_raw] = message['payload']['body']['data']
		else
			message['payload']['parts'].each do |part|
				if part['mimeType'] == 'text/plain'
					email_message[:body_text_raw] = part['body']['data']
				elsif part['mimeType'] == 'text/html'
					email_message[:body_html_raw] = part['body']['data']
				end
				
				if !part['parts'].nil? # go through parts if any
					part['parts'].each do |subpart|
						if subpart['mimeType'] == 'text/plain'
							email_message[:body_text_raw] = subpart['body']['data']
						elsif subpart['mimeType'] == 'text/html'
							email_message[:body_html_raw] = subpart['body']['data']
						end

						if !subpart['parts'].nil?
							subpart['parts'].each do |subsubpart| # go through parts if any
								if subsubpart['mimeType'] == 'text/plain'
									email_message[:body_text_raw] = subsubpart['body']['data']
								elsif subsubpart['mimeType'] == 'text/html'
									email_message[:body_html_raw] = subsubpart['body']['data']
								end
							end
						end
					end
				end
			end
		end

		email_message[:subject] = (message['payload']['headers'].detect { |h| h['name'] == 'Subject' })['value']

		email_message
	end
end