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
  def set_contents(topic,title,tags,content,description)
    self.topic = topic.gsub(' ','_')
    self.title = title.gsub(' ','_')
    self.tags = tags.split(',').map{|k| "tag:#{k.gsub(' ','_')}".downcase}.join(' ')
    self.content = content
    self.description = description
    self.markdown = "#{self.title}\n\n#{self.description}\n\n```\n#{self.content}\n``` \n\n#### Tags\n#{self.tags}\n"
    self.filename = "#{self.topic}/#{self.title}.md".downcase
  end
end
