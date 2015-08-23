class MessageAttachment < ActiveRecord::Base
  belongs_to :email_message
  has_many :attachment_headers
end
