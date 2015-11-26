include ThreadHelper

class EmailThread < ActiveRecord::Base
	include Filterable

	belongs_to :authorisation
	has_many :message_attachments, dependent: :destroy
	has_many :message_participants, dependent: :destroy
	has_many :participants, through: :message_participants
	has_many :tags, dependent: :destroy
  	scope :by_latest_email,  -> { order('latest_email_date desc') }

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

	# Checks if one of the participants belongs to the scope of the authorisation (e.g octave@gocardless.com belongs to 'GoCardless')
	def has_participant_from_scope?
		scope_words = self.authorisation.scope.downcase.gsub(/([_@#!%()\-=;><,{}\~\[\]\.\/\?\"\*\^\$\+\-]+)/, ' ').split(' ')
		# Clean up scope words (e.g if one is email, get domain instead)
		scope_words.each do |word, index|
			if word[/.+@.+\..+/i] # if it has an email format
				scope_words[index.to_i] = parse_email(word)[:company].downcase
			end
		end
		# Go through participants to see if they match the scope (either all scope words or at least 2)
		self.unique_participants.each do |participant|
			check = 0
			scope_words.each do |keyword|
				check += 1 if participant.company.include? keyword.downcase
			end
			return true if check >= 2 or check == scope_words.count
		end
		false
	end

	# How many attachments in the thread
	def count_attachments(include_inline = true)
		if include_inline
			self.message_attachments.count
		else
			self.message_attachments.not_inline.count
		end
	end

	# Is the thread conversation internal?
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
		# TODO: this is no longer possible unless we check it in the initial gmail sync
	#	self.email_messages.each do |email|
	#		internal = true
	#		company = email.participants.first.company
	#		email.participants.each do |participant|
	#			if participant.company != company
	#				internal = false
	#				break
	#			end
	#		end
	#		return 'internal' if internal
	#	end

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

	# Check if the thread is hidden to the requester
	def is_hidden?
		self.tags.where(name: 'user_hidden').count > 0
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

	# Change whether a user hid a thread or not
	def set_hidden(action = true)
		if action
			self.add_tag('user_hidden')
		else
			self.remove_tag('user_hidden')
		end
	end

	# Go through the rules for tags and bulk add / remove them
	def update_tags
		# Email count rule
		if (self.email_count >= 5 or self.count_attachments(false) > 0) and self.has_participant_from_scope?
			self.add_tag('highlight')
		else
			self.remove_tag('highlight')
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
