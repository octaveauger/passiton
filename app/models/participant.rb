class Participant < ActiveRecord::Base
	has_many :message_participants

	def fullname
		[self.first_name, self.last_name].join(' ').squish
	end
end
