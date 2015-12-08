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
  end
end
