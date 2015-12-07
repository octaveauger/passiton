include ThreadHelper

class Participant < ActiveRecord::Base
	has_many :message_participants

	def fullname
		[self.first_name, self.last_name].join(' ').squish
	end

	# Returns only the participants belonging to the scope of the participant_holder (which can be anything that has participants, e.g authorisation or thread)
	# e.g octave@gocardless.com belongs to 'GoCardless'
	def self.from_scope(scope, participant_holder)
		participants_from_scope = []
		scope_words = scope.downcase.gsub(/([_@#!%()\-=;><,{}\~\[\]\.\/\?\"\*\^\$\+\-]+)/, ' ').split(' ')
		# Clean up scope words (e.g if one is email, get domain instead)
		scope_words.each do |word, index|
			if word[/.+@.+\..+/i] # if it has an email format
				scope_words[index.to_i] = parse_email(word)[:company].downcase
			end
		end
		# Go through participants to see if they match the scope (either all scope words or at least 2)
		participant_holder.participants.uniq.each do |participant|
			check = 0
			scope_words.each do |keyword|
				check += 1 if participant.company.include? keyword.downcase
			end
			participants_from_scope.push(participant) if check >= 2 or check == scope_words.count
		end
		participants_from_scope
	end
end
