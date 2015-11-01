class SynchronisationError < ActiveRecord::Base
  belongs_to :authorisation

  def content
  	JSON.parse super
  end
end
