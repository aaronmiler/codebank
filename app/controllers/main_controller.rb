class MainController < ApplicationController
  require 'rest_client'
  require 'base64'
  require 'utilities'
  require 'slim'

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
    @wisdom = Wisdom.new
    info = Github::Repos.new :user => session[:credentials]['login'], :oauth_token => session[:token], :repo => 'tome-of-knowledge'
    if session[:repo] != info.commits.all.first.first.last
      session[:latest_sha] = info.commits.all.first.first.last
    end
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
    repos = Github::Repos.new
    repos.oauth_token = session[:token]
    repos.user = session[:credentials]['login']
    repos.create :name => "tome-of-knowledge"
    repo = Github::Repos::Contents.new  :user => session[:credentials]['login'],
     :oauth_token => session[:token],
     :repo => 'tome-of-knowledge'
    repo.create session[:credentials]['login'], 'tome-of-knowledge', "README.md",
     :path => "README.md",
     :message => "Created Readme",
     :content => @contents

    redirect_to :action => :home
  end
  def new_knowledge

  end
  def save_knowledge
    @topic = params['wisdom']['topic'].gsub(' ','_')
    @contents = "# #{params['wisdom']['title']}\n\n#{params['wisdom']['description']}\n\n```\n#{params['wisdom']['contents']}\n``` \n\n#### Tags\n#{params['wisdom']['tags'].split(',').map{|k| "tag:#{k.gsub(' ','_')}".downcase}.join(' ')}\n"
    if params['wisdom']['topic']
      @file_name = "#{@topic}/#{params['wisdom']['title'].gsub(' ','_')}.md".downcase
      @mode = "100644"
    else
      @file_name = "#{params['wisdom']['title'].gsub(' ','_')}.md".downcase
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
         :path => @file_name,
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
    @file_name = "#{params[:topic]}/#{params[:file]}.md".downcase 
    repo = Github::Repos::Contents.new  :user => session[:credentials]['login'],
     :oauth_token => session[:token],
     :repo => 'tome-of-knowledge'
    @file = repo.find :path => @file_name
    @contents = Base64.decode64(@file.content)
  end

  def edit
    @file_name = "#{params[:topic]}/#{params[:file]}.md".downcase
    @contents = Wisdom.new
    @contents.fetch(session[:credentials]['login'], session[:token], @file_name)
    @contents.seperate()
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
    repo = Github::Repos::Contents.new  :user => session[:credentials]['login'],
      :oauth_token => session[:token],
      :repo => 'tome-of-knowledge'
    repo.delete session[:credentials]['login'], 'tome-of-knowledge', @file_name,
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
    @github = Github.new client_id: ENV['GITHUB_ID'], client_secret: ENV['GITHUB_SECRET']
    @topics = ["Ruby","Java","JavaScript","HTML","CSS","Python","Perl","C","C#","C++","PostgreSQL","SQL","Other"].sort
  end
end
