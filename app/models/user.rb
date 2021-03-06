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
  has_many :managed_delegations, class_name: 'Delegation', foreign_key: 'manager_id', dependent: :destroy
  has_many :employee_delegations, class_name: 'Delegation', foreign_key: 'employee_id', dependent: :destroy
  has_many :managers, through: :employee_delegations
  has_many :employees, through: :managed_delegations

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
        guest: false,
        oauth_cancelled: false,
        is_manager: true
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
        guest: false,
        oauth_cancelled: false,
        is_manager: true
      )
      user.first_token(access_token)
    else
      if user.tokens.last.access_token != access_token
        user.update_token(access_token)
      end
      user.update(oauth_cancelled: false) if user.oauth_cancelled
    end
    ContinuousGmailSyncJob.new.async.perform(user)
    user
  end

  # Tries to find a User, or create a guest account for invites into the app
  # returns nil if it can't create a user
  def self.find_or_create_guest(email)
    user = User.where(email: email).first
    unless user
      user = User.new(
          email: email,
          password: Devise.friendly_token[0,20],
          guest: true
          )
      user = nil unless user.save
    end
    user
  end

  # Set up the first access token once a user authorises the app
  def first_token(access_token)
    self.tokens.create(access_token: access_token.credentials.token,
      refresh_token: access_token.credentials.refresh_token,
      expires_at: Time.at(access_token.credentials.expires_at).to_datetime)
  end

  # If a user cancels the app authorisation, then re-authorise it, update the token
  def update_token(access_token)
    self.tokens.last.update(access_token: access_token.credentials.token,
      refresh_token: access_token.credentials.refresh_token,
      expires_at: Time.at(access_token.credentials.expires_at).to_datetime)
  end

  # Update the user if their token is no longer valid, i.e they've cancelled the oAuth with Passiton on their side
  def register_oauth_cancelled
    self.update(oauth_cancelled: true)
  end

  def can_call_api?
    !self.oauth_cancelled
  end

  # Returns the first and last name (if present)
  def full_name
    self.first_name.to_s + ' ' + self.last_name.to_s
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

  # Returns whether the user has an active delegation with someone managing their account
  def is_managed?
    !self.employee_delegations.active.empty?
  end
  
  # Returns the delegation that is managing the user
  def manager_delegation
    self.employee_delegations.active.first if self.is_managed?
  end

  # Returns the email of either the user or, if they have an active manager delegation, the email of the manager
  def active_email
    manager_delegation = self.manager_delegation
    if manager_delegation.nil?
      self.email
    else
      manager_delegation.manager.email
    end
  end

  # returns true if the current user can access the content for any of the allowed users (i.e they are that user or their active manager)
  def self.can_access(allowed_user_ids = [], current_user_id)
    allowed_user_ids.each do |allowed_user_id|
      allowed_user = User.find(allowed_user_id)
      return true if (allowed_user and (allowed_user_id == current_user_id or (allowed_user.manager_delegation and allowed_user.manager_delegation.manager.id == current_user_id)))
    end
    false
  end

  # Shortcut that includes both requester and granter of an authorisation
  def self.can_access_authorisation(authorisation_id, current_user_id)
    authorisation = Authorisation.find_by(id: authorisation_id)
    if authorisation.nil?
      false
    else
      if authorisation.enabled
        allowed = [authorisation.requester.id, authorisation.granter.id]
      else
        allowed = [authorisation.granter.id]
      end
      User.can_access(allowed, current_user_id)
    end
  end

  # Shortcut that checks if someone can see a specific thread
  def self.can_access_thread(thread_id, current_user_id)
    thread = EmailThread.find_by(id: thread_id)
    !(thread.nil? or !User.can_access_authorisation(thread.authorisation.id, current_user_id) or (!User.can_access([thread.authorisation.granter.id], current_user_id) and thread.is_hidden?))
  end
end
