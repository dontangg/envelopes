class ApplicationController < ActionController::Base
  before_action :authenticate
  before_action :check_new_experience
  protect_from_forgery

  rescue_from CanCan::AccessDenied do |exception|
    # render :file => "#{Rails.root}/public/403.html", :status => 403
    raise ActionController::RoutingError, exception.message
  end

  private

  def authenticate
    unless current_user
      flash[:return_to] = request.fullpath
      redirect_to sign_in_url
    end
  end

  def current_user
    @current_user ||= User.find_by(api_token: params[:api_token]) if params[:api_token]
    @current_user ||= User.find(session[:user_id]) if session[:user_id]

    @current_user
  end

  def current_user_id
    @current_user ? @current_user.id : session[:user_id]
  end

  def check_new_experience
    if params[:ne].to_i == 1
      cookies[:new_experience] = true
    elsif params[:ne].to_i == 0
      cookies.delete :new_experience
    end
  end

  def new_experience?
    cookies[:new_experience] == true
  end

  helper_method :current_user, :current_user_id
end
