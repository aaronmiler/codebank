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
     :repo => 'tome-of-knowledge'
    self.file = repo.find :path => path
  end
  def seperate(contents = self.markdown || Base64.decode64(self.file.content))
    self.title = contents.string_between_markers("# ", "\n").gsub('_',' ').titlecase
    self.tags = contents.string_between_markers("Tags\n", "\n").split(' ').map{ |t| t.gsub('tag:','').gsub('-',' ')}.join(', ').titlecase
    self.content = contents.string_between_markers("```\n", "\n```")
    self.description = contents.string_between_markers("\n\n", "\n\n```")
  end
  def parse(markdown)
    self.markdown = Base64.decode64(markdown)
    self.seperate
  end
  def prepare_for_save(params)
    self.original_title = params['original_title'] if params['original_title']
    self.markdown = "# #{self.title}\n\n#{self.description}\n\n```\n#{self.content}\n``` \n\n#### Tags\n#{self.tags}\n"
    self.filename = "#{self.topic.gsub('#','_sharp')}/#{self.title}.md".downcase
  end
  def save(user, token)
    github = Github::Repos::Contents.new  :user => user,
     :oauth_token => token,
     :repo => 'tome-of-knowledge'
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
  def create(user, github, message = "Added Knowledge: #{self.filename}")
    github.create user, 'tome-of-knowledge', self.filename,
     :path => self.filename,
     :message => message,
     :content => self.markdown
  end
  def remove(user, github, file, message)
    github.delete user, 'tome-of-knowledge', self.original_title,
      :path => self.original_title,
      :message => message,
      :content => self.markdown,
      :sha => file.sha
  end
  def update(user, github, file)
    github.update user, 'tome-of-knowledge', self.filename,
      :path => self.filename,
      :message => "Updated Knowledge: #{self.filename}",
      :content => self.markdown,
      :sha => file.sha
  end
end
