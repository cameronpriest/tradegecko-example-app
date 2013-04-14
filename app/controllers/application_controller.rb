class ApplicationController < ActionController::Base
  protect_from_forgery

  rescue_from OAuth2::Error do |exception|
    if exception.response.status == 401
      begin
        access_token.refresh!
        set_session_from_access_token(access_token)
      rescue
        clear_session
        redirect_to root_url, alert: "Access token expired, try signing in again."
      end
    end
  end

private
  def oauth_client
    @oauth_client ||= OAuth2::Client.new(ENV["OAUTH_ID"], ENV["OAUTH_SECRET"], site: "https://api.tradegecko.com")
  end

  def access_token
    if session[:access_token]
      @access_token ||= OAuth2::AccessToken.new(oauth_client, session[:access_token],
        refresh_token: session[:refresh_token],
        expires_at: session[:expires_at]
      )
    end
  end
  helper_method :access_token

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  helper_method :current_user

  def clear_session
    session.delete(:user_id)
    session.delete(:access_token)
    session.delete(:refresh_token)
    session.delete(:expires_at)
  end

  def set_session_from_access_token(access_token)
    session[:access_token]  = access_token.token
    session[:refresh_token] = access_token.refresh_token
    session[:expires_at]    = access_token.expires_at
  end
end
