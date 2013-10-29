class Wisdom < ActiveRecord::Base 
  require "utilities"
  attr_accessor :title, :topic, :content, :description, :tags, :file, :markdown, :filename, :original_title
  def initialize(attributes = {})
    unless attributes.empty?
      @topic = attributes['topic'].gsub(' ','_')
      @title = attributes['title'].gsub(' ','_')
      @tags = attributes['tags'].split(',').map{|k| "tag:#{k.gsub(' ','_')}".downcase}.join(' ')
      @content = attributes['content']
      @description = attributes['description']
    end
  end
  def fetch(user, token, path)
    repo = Github::Repos::Contents.new  :user => user,
     :oauth_token => token,
     :repo => ENV['REPO_NAME']
    self.file = repo.find :path => path
  end
  def seperate(contents = self.markdown || Base64.decode64(self.file.content))
    self.title = contents.get_title("# ", "\n<!--- desc --->")
    self.tags = contents.get_tags("<!--- tags --->", "<!--- end_tags --->")
    self.content = contents.string_between_markers("```\n", "\n```\n#### Tags")
    self.description = contents.string_between_markers("<!--- desc --->\n", "\n<!--- end_desc --->")
  end
  def parse(markdown)
    self.markdown = Base64.decode64(markdown)
    self.seperate
  end
  def prepare_for_save(params)
    self.original_title = params['original_title'] if params['original_title']
    self.markdown = "# #{self.title}\n<!--- desc --->\n#{self.description}\n<!--- end_desc --->\n```\n#{self.content}\n```\n#### Tags\n<!--- tags --->\n#{self.tags}\n<!--- end_tags --->"
    self.filename = "#{self.topic.gsub('#','_sharp')}/#{self.title}.md".downcase
  end
  def save(user, token)
    github = Github::Repos::Contents.new  :user => user,
     :oauth_token => token,
     :repo => ENV['REPO_NAME']
    begin
      if self.original_title != self.filename && self.original_title
        file = github.find :path => self.original_title
        self.remove(user, github, file, "Renamed #{self.original_title} to #{self.filename}")
        self.create(user, github, "Renamed #{self.original_title} to #{self.filename}")
      else
        file = github.find :path => self.filename
        self.update(user, github, file)
      end
    rescue Github::Error::GithubError => e
      if e.is_a? Github::Error::ServiceError
        self.create(user, github)
      end
    end
  end
  def create(user, github, message = "Deposited: #{self.filename}")
    github.create user, ENV['REPO_NAME'], self.filename,
      :path => self.original_title,
      :message => message,
      :content => self.markdown
  end
  def remove(user, github, file, message)
    github.delete user, ENV['REPO_NAME'], self.original_title,
      :path => self.original_title,
      :message => message,
      :sha => file.sha
  end
  def update(user, github, file)
    github.update user, ENV['REPO_NAME'], self.filename,
      :message => "Updated: #{self.filename}",
      :content => self.markdown,
      :sha => file.sha
  end
end
