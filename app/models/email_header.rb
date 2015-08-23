include ApplicationHelper

class EmailHeader < ActiveRecord::Base
  belongs_to :email_message

  def self.email_from_participant(value)
  	between(value, { start: '<', end: '>' })
  end
end
