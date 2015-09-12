class MessageAttachment < ActiveRecord::Base
  belongs_to :email_message
end
