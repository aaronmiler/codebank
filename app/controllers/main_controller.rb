class MainController < ApplicationController
  require 'rest_client'
  require 'base64'
  require 'utilities'
  require 'slim'

  before_filter :check_login, :except => [:index,:callback,:login,:logout]
  before_filter :setup, :except => [:index]

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
    @wisdom = Wisdom.new
    session[:latest_sha] = @repo.commits.all.first.first.last
    unless session[:has_repo] == true
      @has_repo = @github.repos.list user: session[:credentials]['login']
      @has_repo.map { |r| session[:has_repo] = true if r.name == "tome-of-knowledge" }
    end
    @contents = @github.git_data.trees.get session[:credentials]['login'], 'tome-of-knowledge', session[:latest_sha], :oauth_token => session[:token]
    @files = []

    #github = Github.new :oauth_token => session[:token]
    #github.login
  end

  def create_repo
    @repos.create :name => "tome-of-knowledge"
    @repo.create session[:credentials]['login'], 'tome-of-knowledge', "README.md",
     :path => "README.md",
     :message => "Created Readme",
     :content => @contents

    redirect_to :action => :home
  end
  def new_knowledge

  end
  def save_knowledge
    @wisdom = Wisdom.new
    @wisdom.set_contents(params['wisdom'])
    @wisdom.save(session[:credentials]['login'],session[:token])
  end
  def logout
    reset_session
    redirect_to :action => :index
  end

  def view
    @file_name = "#{params[:topic]}/#{params[:file]}.md".downcase 
    @file = @repo.contents.find :path => @file_name
    @contents = Base64.decode64(@file.content)
  end

  def edit
    @file_name = "#{params[:topic]}/#{params[:file]}.md".downcase
    @contents = Wisdom.new
    @contents.fetch(session[:credentials]['login'], session[:token], @file_name)
    @contents.seperate()
  end

  def topic
    @contents = @repo.contents.find :path => params[:topic]
  end

  def search

  end

  def results
    tags = params['query'].scan(/\((\w+)\)/)
    tags.map{|t| "tag:#{t.to_s.gsub(' ','_')}".downcase}
    tags = tags.join(' ')
    query = params['query'].gsub(/tag\((\w+)\)\s*/,'')
    @query = "#{tags} #{query} repo:#{session[:credentials]['login']}/tome-of-knowledge in:path,file"
    
    client = Octokit::Client.new :access_token => session[:token]
    @results =  client.search_code(@query)
    
  end

  def delete
    @file_name = "#{params[:topic]}/#{params[:file]}.md"
    @repo.contents.delete session[:credentials]['login'], 'tome-of-knowledge', @file_name,
      :path => @file_name,
      :sha => params['sha'],
      :message => "Removed Knowledge: #{@file_name}"
    render :json => {status: "Deleted", file_name: params[:file]}

  end

  private

  def check_login
    redirect_to :action => :index if session[:credentials].blank?
  end
  def setup    
    @github = Github.new client_id: ENV['GITHUB_ID'], client_secret: ENV['GITHUB_SECRET'], :oauth_token => session[:token]
    @repo = Github::Repos.new  :user => session[:credentials]['login'], :oauth_token => session[:token], :repo => 'tome-of-knowledge'
    @topics = ["Ruby","Java","JavaScript","HTML","CSS","Python","Perl","C","C#","C++","PostgreSQL","SQL","Other"].sort
  end
end
