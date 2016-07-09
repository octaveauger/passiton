class Delegation < ActiveRecord::Base
	belongs_to :manager, class_name: 'User'
	belongs_to :employee, class_name: 'User'
	validates :manager_id, presence: true
	validates :employee_id, presence: true
end
