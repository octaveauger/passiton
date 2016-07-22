class StaticPagesController < ApplicationController
	layout 'marketing'

	def home
    	@container = false
	end
end
