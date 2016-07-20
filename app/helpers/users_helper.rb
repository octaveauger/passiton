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
		redirect || authorisations_path
	end

	# Manager section

	def is_manager
		unless current_user.is_manager
			redirect_to root_path
		end
	end

	# Admin section

	def admin_log_in(admin)
		session[:admin_id] = admin.id
	end

	def current_admin
		@current_admin ||= Admin.find_by(id: session[:admin_id])
	end

	def admin_signed_in?
		!current_admin.nil?
	end

	def logged_in_admin
		unless current_admin
			store_location
			redirect_to new_admin_session_path
		end
	end

	def admin_log_out
	    session.delete(:admin_id)
	    @current_admin = nil
	end
end
