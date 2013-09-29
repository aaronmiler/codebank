class Wisdom < ActiveRecord::Base
  attr_accessor :title, :topic, :content, :description, :tags, :file
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
end
