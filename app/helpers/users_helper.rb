module UsersHelper

	def logged_in_user
		unless current_user
			store_location
			redirect_to user_omniauth_authorize_path(:google_oauth2), notice: "Please connect via Gmail first"
		end
	end

	def store_location
		session[:return_to] = request.url if request.get?
	end

	def after_sign_in_path_for(resource)
		redirect = session[:return_to]
		session.delete(:return_to)
		redirect || root_path
	end
end
