class Delegation < ActiveRecord::Base
	include Tokenable

	belongs_to :manager, class_name: 'User'
	belongs_to :employee, class_name: 'User'
	validates :manager_id, presence: true
	validates :employee_id, presence: true
	attr_accessor :employee_email, :description
	scope :active, -> { where(:is_active => true) }

	def activate
		Delegation.deactivate_all(self)
		self.update(is_active: true)
		DelegationMailer.confirm_delegation(self).deliver
	end

	def deactivate(role)
		if self.is_active #only email if it's currently active
			DelegationMailer.revoke_delegation(self).deliver if role == 'employee'
			DelegationMailer.cancel_delegation(self).deliver if role == 'manager'
		end
		self.update(is_active: false)
	end

	# Deactivate any other active delegation for that employee
	def self.deactivate_all(active_delegation)
		active_delegation.employee.employee_delegations.active.each do |delegation|
			delegation.deactivate('employee')
		end
	end

	def status
		self.is_active ? 'active' : 'not active'
	end
end
