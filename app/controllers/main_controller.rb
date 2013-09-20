class MainController < ApplicationController
  require 'rest_client'
  before_filter :check_login, :except => [:index,:callback,:login,:logout]
  before_filter :setup_github

  def index
  end

  def callback
    response = RestClient.get "http://localhost:9999/authenticate/#{params['code']}"
    session[:token] = JSON.parse(response)['token']
    session[:credentials] = JSON.parse(RestClient.get "https://api.github.com/user?access_token=#{session[:token]}")
    redirect_to :action => :home
  end

  def login    
    address = @github.authorize_url redirect_uri: 'http://localhost:3000/callback', scope: 'repo'
    redirect_to address
  end

  def home
    @knowledge = Github::Repos.new
    @knowledge.oauth_token = session[:token]
    @knowledge.user = session[:credentials]['login']
    @knowledge.contents :repo => "tome-of-knowledge"
    @has_repo = @github.repos.list user: session[:credentials]['login']
    @created = false
    @has_repo.each do |r|
      @created = true if r.name == "tome-of-knowledge"
    end

    #github = Github.new :oauth_token => session[:token]
    #github.login
  end

  def create_repo
    repos = Github::Repos.new
    repos.oauth_token = session[:token]
    repos.user = session[:credentials]['login']
    repos.create :name => "tome-of-knowledge"
    redirect_to :action => :home
  end

  def logout
    reset_session
    redirect_to :action => :index
  end

  private

  def check_login
    redirect_to :action => :index if session[:credentials].blank?
  end
  def setup_github
    @github = Github.new client_id: ENV['GITHUB_ID'], client_secret: ENV['GITHUB_SECRET']
  end
end
