include ThreadHelper

class EmailThread < ActiveRecord::Base
	include Filterable

	belongs_to :authorisation
	has_many :email_messages
	has_many :message_attachments, through: :email_messages
	has_many :message_participants, through: :email_messages
	has_many :participants, through: :message_participants
	has_many :tags

	# Returns the subject line of a thread
	def subject
		self.email_messages.order('email_messages.internal_date asc').first.subject
	end

	# Returns the datetime of the first email in the thread
	def first_email_date
		Time.at((self.email_messages.order('email_messages.internal_date asc').first.internal_date.to_i/1000).to_i).utc.to_datetime
	end

	# Returns the datetime of the last email in the thread
	def last_email_date
		Time.at((self.email_messages.order('email_messages.internal_date desc').first.internal_date.to_i/1000).to_i).utc.to_datetime
	end

	# Returns an array of label names, types etc. for the thread
	def readable_labels
		user_labels = {}
		self.authorisation.granter.labels.all.each do |user_label|
			user_labels[user_label.label_id] = { id: user_label.id, label_id: user_label.label_id, name: user_label.name, label_type: user_label.label_type }
		end
		readable_labels = []
		JSON.parse(self.labels).each do |label_id|
			readable_labels.push(user_labels[label_id]) unless user_labels[label_id].nil?
		end
		readable_labels
	end

	# Unique participants to this thread
	def unique_participants
		self.participants.uniq
	end

	# Returns participants with a delivery in: 'to', 'from', 'cc', 'bcc'
	def participants_with_delivery(delivery)
		self.participants.joins(:message_participants).where('message_participants.delivery = ?', delivery).uniq
	end

	def unique_senders
		self.participants_with_delivery('from').uniq
	end

	# How many emails in the thread
	def count_emails
		self.email_messages.count
	end

	# How many attachments in the thread
	def count_attachments(include_inline = true)
		if include_inline
			self.message_attachments.count
		else
			self.message_attachments.not_inline.count
		end
	end

	# Is the thread conversation internal? TODO: add more types, e.g internal only, external...
	def conversation_type
		# Check if the conversation is internal only, i.e everyone has the same company
		company = self.participants.first.company
		internal_only = true
		self.participants.each do |participant|
			if participant.company != company
				internal_only = false
				break
			end
		end
		return 'internal_only' if internal_only

		# Check if the conversation has any internal emails (email by email), where all participants have the same company
		self.email_messages.each do |email|
			internal = true
			company = email.participants.first.company
			email.participants.each do |participant|
				if participant.company != company
					internal = false
					break
				end
			end
			return 'internal' if internal
		end

		# If we reach this point, it means nothing was internal
		return 'external'
	end

	# Check if the thread has a specific tag
	def has_tag?(tag)
		self.tags.where(name: tag).count > 0
	end

	# Check if the thread is highlighted
	def is_highlighted?
		self.tags.where(name: ['highlight', 'user_highlight']).where.not(name: 'user_not_highlight').count > 0
	end

	# Change whether a user highlighted a thread or not
	def set_highlight(action = true)
		if action
			self.add_tag('user_highlight')
			self.remove_tag('user_not_highlight')
		else
			self.add_tag('user_not_highlight')
			self.remove_tag('user_highlight')
		end
	end

	# Go through the rules for tags and bulk add / remove them
	def update_tags
		# Email count rule
		if self.count_emails >= 5 or self.count_attachments(false) > 0
			self.add_tag('highlight')
		end
		# Internal discussion rule
		case self.conversation_type
		when 'internal_only'
			self.add_tag('internal_only')
			self.add_tag('internal')
		when 'internal'
			self.add_tag('internal')
			self.add_tag('external') #it's not internal only so it's also external
			self.remove_tag('internal_only')
		when 'external'
			self.add_tag('external')
			self.remove_tag('internal_only')
		end
	end

	# Add a tag to this thread (unless it exists already)
	def add_tag(tag_name)
		self.tags.create(name: tag_name) if self.tags.find_by(name: tag_name).nil?
	end

	# Remove a tag from this thread (if it existed)
	def remove_tag(tag_name)
		self.tags.where(name: tag_name).destroy_all
	end

	# Filters based on a tab name
	def self.tab_filter(tab)
		case tab
		when 'all'
			self.all
		when 'highlight'
			self.where('tags.name = ? OR tags.name = ?', 'highlight', 'user_highlight').where.not('tags.name = ?', 'user_not_highlight')
		when 'internal'
			self.where('tags.name = ?', tab)
		else
			self.all
		end
	end

end
