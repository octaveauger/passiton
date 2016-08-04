class Admin::UsersController < ApplicationController
  before_action :logged_in_admin
  layout 'admin'

  def index
  	@users = User.order('id desc').all.paginate(page: params[:page])
  	respond_to do |format|
      format.html
      format.js
    end
  end

  def show
  	@user = User.find_by(id: params['id'])
    redirect_to admin_users_path, alert: 'This user does not exist' and return if @user.nil?
    @requested_authorisations = @user.requested_authorisations.order('id desc').all
    @granted_authorisations = @user.granted_authorisations.order('id desc').all
    @managed_delegations = @user.managed_delegations.order('id desc').all
  end
end
