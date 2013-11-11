class ApplicationController < ActionController::Base
  before_filter :authenticate
  protect_from_forgery

  rescue_from CanCan::AccessDenied do |exception|
    # render :file => "#{Rails.root}/public/403.html", :status => 403
    raise ActionController::RoutingError, exception.message
  end

  private

  def authenticate
    unless current_user
      flash[:return_to] = request.fullpath
      redirect_to login_url
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

  helper_method :current_user, :current_user_id
end
