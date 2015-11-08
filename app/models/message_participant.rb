class MessageParticipant < ActiveRecord::Base
  belongs_to :email_thread
  belongs_to :participant
end
