class Admin::SessionsController < ApplicationController
  layout 'admin'

  def new
  end

  def create
  	admin = Admin.find_by(email: params[:session][:email].downcase)
  	if admin && admin.authenticate(params[:session][:password])
  		admin_log_in(admin)
  		redirect_to admin_users_path and return
  	else
  		flash[:alert] = 'Incorrect'
  		render 'new'
  	end
  end

  def destroy
  	admin_log_out
  	redirect_to root_path and return
  end
end
