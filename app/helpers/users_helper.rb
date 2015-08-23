module UsersHelper

	def logged_in_user
		redirect_to root_path, notice: "Please login first" unless current_user
	end
end
