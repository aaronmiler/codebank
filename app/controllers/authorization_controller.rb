class AuthorizationController < ApplicationController

  def callback
    @github = Github.new client_id: ENV['GITHUB_ID'], client_secret: ENV['GITHUB_SECRET'], :oauth_token => session[:token]
    access_token = @github.get_token params['code']
    session[:token] = access_token.token
    session[:credentials] = JSON.parse(RestClient.get "https://api.github.com/user?access_token=#{session[:token]}")
    redirect_to :action => :has_repo
  end
  def has_repo
    session[:has_repo] = Utility.has_repo?(session[:credentials]['login'],session[:token]) unless session[:has_repo] == true    
    if session[:has_repo] == false
      redirect_to :action => :need_repo
    else
      redirect_to '/home'
    end
  end
  def create_repo
    repos = Github::Repos.new :oauth_token => session[:token],
      :user => session[:credentials]['login']
    repos.create :name => "tome-of-knowledge", :auto_init => true
    redirect_to '/home'
  end
  def login       
    reset_session 
    @github = Github.new client_id: ENV['GITHUB_ID'], client_secret: ENV['GITHUB_SECRET'], :oauth_token => session[:token]
    address = @github.authorize_url redirect_uri: "http://knowledge.labs.aaronmiler.com/authorization/callback", scope: 'repo'
    redirect_to address
  end
  def logout
    reset_session
    redirect_to :action => :index
  end
end
