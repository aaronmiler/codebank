class Wisdom < ActiveRecord::Base
  attr_accessor :title, :topic, :content, :description, :tags, :file, :markdown, :filename
  def fetch(user, token, path)
    repo = Github::Repos::Contents.new  :user => user,
     :oauth_token => token,
     :repo => 'tome-of-knowledge'
    self.file = repo.find :path => path
  end
  def seperate()
    contents = Base64.decode64(self.file.content)
    self.topic = self.file.path.scan(/^[^\/]*/).join('').gsub('_',' ').titlecase
    self.title = contents.string_between_markers("#", "\n")
    self.tags = contents.string_between_markers("Tags\n", "\n").split(' ')
    self.content = contents.string_between_markers("```\n", "```")
    self.description = contents.string_between_markers("\n\n", "\n```")
  end
  def set_contents(params)
    self.topic = params['topic'].gsub(' ','_')
    self.title = params['title'].gsub(' ','_')
    self.tags = params['tags'].split(',').map{|k| "tag:#{k.gsub(' ','_')}".downcase}.join(' ')
    self.content = params['content']
    self.description = params['description']
    self.markdown = "#{self.title}\n\n#{self.description}\n\n```\n#{self.content}\n``` \n\n#### Tags\n#{self.tags}\n"
    self.filename = "#{self.topic}/#{self.title}.md".downcase
  end
  def save(user, token)
    github = Github::Repos::Contents.new  :user => user,
     :oauth_token => token,
     :repo => 'tome-of-knowledge'
    begin
      file = github.find :path => self.filename
      github.update user, 'tome-of-knowledge', self.filename,
        :path => self.filename,
        :message => "Updated Knowledge: #{self.filename}",
        :content => self.markdown,
        :sha => file.sha
    rescue Github::Error::GithubError => e
      if e.http_status_code == 404
        github.create user, 'tome-of-knowledge', self.filename,
         :path => self.filename,
         :message => "Added Knowledge: #{self.filename}",
         :content => self.markdown
      end
    end
  end
end
