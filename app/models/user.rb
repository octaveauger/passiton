include ThreadHelper

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  devise :omniauthable, :omniauth_providers => [:google_oauth2]

  has_many :tokens, dependent: :destroy
  has_many :requested_authorisations, class_name: 'Authorisation', foreign_key: 'requester_id', dependent: :destroy
  has_many :granted_authorisations, class_name: 'Authorisation', foreign_key: 'granter_id', dependent: :destroy
  has_many :requesters, through: :requested_authorisations
  has_many :granters, through: :granted_authorisations
  has_many :email_threads, through: :requested_authorisations
  has_many :message_attachments, through: :email_threads
  has_many :labels

  # Manages the connection to Gmail and the User population
  def self.find_for_google_oauth2(access_token, signed_in_resource=nil)
    data = access_token.info
    user = User.where(email: data["email"]).first
    if user.nil?
      user = User.create(
        email: data["email"],
        password: Devise.friendly_token[0,20],
        provider: access_token.provider,
        uid: access_token.uid,
        first_name: data['first_name'],
        last_name: data['last_name'],
        image: data['image'],
        gender: access_token.extra['raw_info']['gender'],
        guest: false
      )
      user.first_token(access_token)
    elsif user.guest
      user.update!(
        provider: access_token.provider,
        uid: access_token.uid,
        first_name: data['first_name'],
        last_name: data['last_name'],
        image: data['image'],
        gender: access_token.extra['raw_info']['gender'],
        guest: false
      )
      user.first_token(access_token)
    end
    ContinuousGmailSyncJob.new.async.perform(user)
    user
  end

  # Tries to find a User, or create a guest account for invites into the app
  def self.find_or_create_guest(email)
    user = User.where(email: email).first
    unless user
      user = User.create!(
          email: email,
          password: Devise.friendly_token[0,20],
          guest: true
          )
    end
    user
  end

  # Set up the first access token once a user authorises the app
  def first_token(access_token)
    self.tokens.create(access_token: access_token.credentials.token,
      refresh_token: access_token.credentials.refresh_token,
      expires_at: Time.at(access_token.credentials.expires_at).to_datetime)
  end

  # Returns the first and last name (if present) and email
  def full_identity
    if self.first_name.nil? or self.last_name.nil?
      self.email
    else
      self.first_name + ' ' + self.last_name + ' (' + self.email + ')'
    end
  end

  # Returns a hash with the name, domain name and email address
  def parse_email
    parse_email(self.email)
  end
end
