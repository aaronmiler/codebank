class MainController < ApplicationController
  require 'rest_client'
  require 'base64'
  require 'utilities'

  before_filter :check_login, :except => [:index,:callback,:login,:logout]
  before_filter :setup

  def index
  end

  def callback

    access_token = @github.get_token params['code']
    session[:token] = access_token.token
    session[:credentials] = JSON.parse(RestClient.get "https://api.github.com/user?access_token=#{session[:token]}")
    redirect_to :action => :home
  end

  def login    
    address = @github.authorize_url redirect_uri: 'http://localhost:3000/callback', scope: 'public_repo'
    redirect_to address
  end

  def home
    info = Github::Repos.new :user => session[:credentials]['login'], :oauth_token => session[:token], :repo => 'tome-of-knowledge'
    if session[:repo] != info.commits.all.first.first.last
      session[:latest_sha] = info.commits.all.first.first.last
    end
    unless session[:has_repo] == true
      puts "RAN has_repo ==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=="
      @has_repo = @github.repos.list user: session[:credentials]['login']
      @has_repo.map { |r| session[:has_repo] = true if r.name == "tome-of-knowledge" }
    end
    @contents = @github.git_data.trees.get session[:credentials]['login'], 'tome-of-knowledge', session[:latest_sha]
    @files = []


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
  def new_knowledge

  end
  def save_knowledge
    @contents = "# #{params[:title]}\n\n#{params[:description]}\n\n```\n#{params[:contents]}\n``` \n\n#### Tags\n#{params[:tags].split(',').map{|k| "tag:#{k.gsub(' ','_')}"}.join(' ')}\n"
    if params[:topic]
      @file_name = "#{params[:topic]}/#{params[:title].gsub(' ','-')}.md"
      @mode = "100644"
    else
      @file_name = "#{params[:title].gsub(' ','-')}.md"
      @mode = "100644"
    end
    #git_data = Github::GitData.new

    repo = Github::Repos::Contents.new  :user => session[:credentials]['login'],
     :oauth_token => session[:token],
     :repo => 'tome-of-knowledge'
    begin
      file = repo.find :path => @file_name
      repo.update session[:credentials]['login'], 'tome-of-knowledge', @file_name,
        :path => @file_name,
        :message => "Updated Knowledge: #{@file_name}",
        :content => @contents,
        :sha => file.sha
    rescue Github::Error::GithubError => e
      if e.http_status_code == 404
        repo.create session[:credentials]['login'], 'tome-of-knowledge', @file_name,
         :path => "hello.md",
         :message => "Added Knowledge: #{@file_name}",
         :content => @contents
      end
    end

    @display = repo.find :path => @file_name

  end
  def logout
    reset_session
    redirect_to :action => :index
  end

  def view
    @file_name = "#{params[:topic]}/#{params[:file]}.md" 
    repo = Github::Repos::Contents.new  :user => session[:credentials]['login'],
     :oauth_token => session[:token],
     :repo => 'tome-of-knowledge'
    @file = repo.find :path => @file_name
  end

  def edit
    @file_name = "#{params[:topic]}/#{params[:file]}.md" 
    repo = Github::Repos::Contents.new  :user => session[:credentials]['login'],
     :oauth_token => session[:token],
     :repo => 'tome-of-knowledge'
    @file = repo.find :path => @file_name
    @contents = Base64.decode64(@file.content)
  end
  def topic
    @topic = params[:topic]
    repo = Github::Repos::Contents.new  :user => session[:credentials]['login'],
         :oauth_token => session[:token],
         :repo => 'tome-of-knowledge'
        @contents = repo.find :path => params[:topic]
  end

  def search

  end
  def results
    @search = Github::Search.new  :user => session[:credentials]['login'],
     :oauth_token => session[:token],
     :repo => 'tome-of-knowledge'
    puts @search.code
  end

  private

  def check_login
    redirect_to :action => :index if session[:credentials].blank?
  end
  def setup
    @github = Github.new client_id: ENV['GITHUB_ID'], client_secret: ENV['GITHUB_SECRET']
    @topics = ["Ruby","Java","JavaScript","HTML","CSS","Python","Perl","C","C#","C++","PostgreSQL","SQL","Other"].sort
  end
end
