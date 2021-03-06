require 'net/http'
require 'json'

class Token < ActiveRecord::Base
  belongs_to :user

  validates :user_id, presence: true
  validates :access_token, presence: true
  validates :refresh_token, presence: true
  validates :expires_at, presence: true

  #https://www.twilio.com/blog/2014/09/gmail-api-oauth-rails.html
  #User.tokens.last.fresh_token will always be an up-to-date token (refreshes if expired)

  def to_params
  	{'refresh_token' => refresh_token,
  		'client_id' => ENV['GOOGLE_CLIENT_ID'],
		  'client_secret' => ENV['GOOGLE_CLIENT_SECRET'],
		  'grant_type' => 'refresh_token'}
  end

  def request_token_from_google
  	url = URI("https://accounts.google.com/o/oauth2/token")
	  Net::HTTP.post_form(url, self.to_params)
  end

  def refresh!
  	response = request_token_from_google
	  data = JSON.parse(response.body)
	  update_attributes(
		  access_token: data['access_token'],
		  expires_at: Time.now + (data['expires_in'].to_i).seconds)
  end

  def expired?
	  expires_at < Time.now
  end

  def fresh_token
  	refresh! if expired?
	  access_token
  end
end
