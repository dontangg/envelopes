class SessionsController < ApplicationController
  skip_before_action :authenticate

  def new
    flash.keep[:return_to]
  end

  def create
    user = User.find_by email: params[:email]
    if user && user.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to flash[:return_to] || root_url, notice: "You are signed in!"
    else
      flash.keep[:return_to]
      flash.now.alert = "Invalid email or password"
      render "new"
    end
  end

  def destroy
    session[:user_id] = nil

    redirect_to sign_in_url, notice: "You have signed out!"
  end
end
