class AuthorizationController < ApplicationController

  def callback
    @github = Github.new client_id: ENV['GITHUB_ID'], client_secret: ENV['GITHUB_SECRET'], :oauth_token => session[:token]
    access_token = @github.get_token params['code']
    session[:token] = access_token.token
    session[:credentials] = JSON.parse(RestClient.get "https://api.github.com/user?access_token=#{session[:token]}")
    redirect_to "/home"
  end
  def login       
    reset_session 
    @github = Github.new client_id: ENV['GITHUB_ID'], client_secret: ENV['GITHUB_SECRET'], :oauth_token => session[:token]
    address = @github.authorize_url redirect_uri: 'http://knowledge.labs.aaronmiler.com/authorization/callback', scope: 'public_repo'
    redirect_to address
  end
  def logout
    reset_session
    redirect_to :action => :index
  end
end
