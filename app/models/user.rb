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
end
