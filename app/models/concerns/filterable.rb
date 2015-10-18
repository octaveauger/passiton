module Filterable
	extend ActiveSupport::Concern

	module ClassMethods
		def name_of_class
			ActiveModel::Naming.plural(self)
		end

		# Runs through all filtering parameters from form and trigger the right 'where' (from this module or the model)
		def filter(filtering_params)
			results = self.where(nil)
			filtering_params.each do |key, value|
				results = results.public_send(key, value) if value.present?
			end
			results
		end
	end
end