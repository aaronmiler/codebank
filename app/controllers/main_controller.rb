class MainController < ApplicationController

  before_filter :check_login, :except => [:need_repo]
  before_filter :setup, :except => [:need_repo]
  before_filter :setup_topics, :only => [:home, :edit]
  def create_repo
    @contents = "# The Tome of Knowledge\nThis is the Tome of Knowledge. A repo filled with markdown files of code bits and things."
    @github.repos.create :name => "tome-of-knowledge"
    @github.repos.create session[:credentials]['login'], 'tome-of-knowledge', "README.md",
      :path => "README.md",
      :message => "Created Readme",
      :content => @contents
    redirect_to :action => :home
  end
  def save_knowledge
    @wisdom = Wisdom.new
    @wisdom.set_contents(params['wisdom'])
    @wisdom.save(session[:credentials]['login'],session[:token])
  end
  def view
    @file_name = "#{params[:topic]}/#{params[:file]}.md".downcase 
    @file = @repo.contents.find :path => @file_name
    @wisdom = Wisdom.new
    @wisdom.seperate(@file.content)
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
    redirect_to :root if session[:credentials].blank?
  end
  def setup        
    @github = Github.new client_id: ENV['GITHUB_ID'], client_secret: ENV['GITHUB_SECRET'], :oauth_token => session[:token]
    @repo = Github::Repos.new  :user => session[:credentials]['login'], :oauth_token => session[:token], :repo => 'tome-of-knowledge'
  end
  def setup_topics
    @contents = @github.git_data.trees.get session[:credentials]['login'], 'tome-of-knowledge', @repo.commits.all.first.first.last, :oauth_token => session[:token]
    @topics = ["Ruby","Java","JavaScript","HTML","CSS","Python","Perl","C","C#","C++","PostgreSQL","SQL","Other"].sort
    session[:custom_topics] = Utility.set_custom_topics(@contents, @topics)
  end
end
