class MessageParticipant < ActiveRecord::Base
  belongs_to :email_message
  belongs_to :participant
end
