class Admin < ActiveRecord::Base
	validates :email, presence: true, uniqueness: { case_sensitive: false }
	validates :password, length: { minimum: 10 }
	has_secure_password
end
