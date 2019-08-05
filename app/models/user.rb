class User
  
  attr_reader :name
  
  def initialize(username)
    @name = username
  end
  
  def self.get_root_url(username, request:)
    return "//#{request.host_with_port}#{User.new(username).get_url}"
  end
  
  def get_url
    return "/user/#{@name}"
  end
  
  def self.downloaded_users
    dirs = Dir.each_child('public/lj')
    return @@downloaded_users ||= dirs.map do |sub|
      if sub.start_with?('.') == false && File.directory?('public/lj/' + sub)
        User.new(sub)
      end
    end.compact
  end
end
