class String
  def string_between_markers marker1, marker2
    self[/#{Regexp.escape(marker1)}(.*?)#{Regexp.escape(marker2)}/m, 1]
  end
  def safe_breaks
    safe_join(%Q{self}.split('\n'),'<br/>')
  end
end
class Utility
  def has_repo?
    github = Github.new client_id: ENV['GITHUB_ID'], client_secret: ENV['GITHUB_SECRET'], :oauth_token => session[:token]
    has_repo = github.repos.list user: session[:credentials]['login']
    has_repo.each do |r|
      next if session[:has_repo] == true
      session[:has_repo] = true if r.name == "tome-of-knowledge"      
    end
  end
end