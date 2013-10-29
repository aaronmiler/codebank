class MainController < ApplicationController

  before_filter :check_login, :except => [:need_repo]
  before_filter :setup
  before_filter :setup_topics, :only => [:home, :edit]
  # def home
  #   render :json => session[:credentials]
  # end
  def save_knowledge
    @wisdom = Wisdom.new(params['wisdom'])
    @wisdom.prepare_for_save(params['wisdom'])
    @wisdom.save(session[:credentials]['login'],session[:token])
  end
  def view
    @file_name = "#{params[:topic]}/#{params[:file]}.md".downcase 
    @file = @repo.contents.find :path => @file_name
    @wisdom = Wisdom.new
    @wisdom.parse(@file.content)
  end
  def edit
    @contents = Wisdom.new()
    @contents.fetch(session[:credentials]['login'], session[:token], "#{params[:topic]}/#{params[:file]}.md".downcase)
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
    @query = "#{tags} #{query} repo:#{session[:credentials]['login']}/codebank-account in:path,file"    
    client = Octokit::Client.new :access_token => session[:token]
    @results =  client.search_code(@query)    
  end
  def delete
    @file_name = "#{params[:topic]}/#{params[:file]}.md"
    @repo.contents.delete session[:credentials]['login'], ENV['REPO_NAME'], @file_name,
      :path => @file_name,
      :sha => params['sha'],
      :message => "Removed Code: #{@file_name}"
    render :json => {status: "Deleted", file_name: params[:file]}
  end

  private
  def check_login
    redirect_to :root if session[:credentials].blank?
  end
  def setup        
    @github = Github.new client_id: ENV['GITHUB_ID'], client_secret: ENV['GITHUB_SECRET'], :oauth_token => session[:token]
    @repo = Github::Repos.new  :user => session[:credentials]['login'], :oauth_token => session[:token], :repo => ENV['REPO_NAME']
    @repos = Github::Repos.new  :user => session[:credentials]['login'], :oauth_token => session[:token]
  end
  def setup_topics
    @contents = @github.git_data.trees.get session[:credentials]['login'], ENV['REPO_NAME'], @repo.commits.all.first.first.last, :oauth_token => session[:token]
    @topics = ["Ruby","Java","JavaScript","HTML","CSS","Python","Perl","C","C++","PostgreSQL","SQL","Other"].sort
    session[:custom_topics] = Utility.set_custom_topics(@contents, @topics)
  end
end
