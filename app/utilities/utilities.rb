class String
  def string_between_markers marker1, marker2
    self[/#{Regexp.escape(marker1)}(.*?)#{Regexp.escape(marker2)}/m, 1]
  end
  def get_tags marker1, marker2
    self[/#{Regexp.escape(marker1)}(.*?)#{Regexp.escape(marker2)}/m, 1].split(' ').map{ |t| t.gsub('tag:','').gsub('-',' ')}.join(', ').titlecase
  end
  def get_title marker1, marker2
    self[/#{Regexp.escape(marker1)}(.*?)#{Regexp.escape(marker2)}/m, 1].gsub('_',' ').titlecase
  end
  def safe_breaks
    safe_join(%Q{self}.split('\n'),'<br/>')
  end
end
class Utility
  def self.has_repo?(user, token)
    github = Github.new client_id: ENV['GITHUB_ID'], client_secret: ENV['GITHUB_SECRET'], :oauth_token => token
    has_repo = github.repos.list user: user
    repo = false
    has_repo.each do |r|
      next if repo == true
      repo = true if r.name == "tome-of-knowledge"      
    end
    return repo
  end
  def self.set_custom_topics(contents,topics)
    custom_topics = []
    contents.tree.each do |c|
      unless topics.any?{ |s| s.casecmp(c.path)==0 }
        next if c.type == "blob"
        custom_topics << c.path.gsub('_',' ').titlecase
      end
    end
    return custom_topics
  end
end