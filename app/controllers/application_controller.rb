class ApplicationController < ActionController::Base
  before_filter :authenticate
  protect_from_forgery
  
  private
  
  def authenticate
    unless current_user
      flash[:return_to] = request.fullpath
      redirect_to login_url
    end
  end
  
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  
  def current_user_id
    session[:user_id]
  end
  
  helper_method :current_user
end
