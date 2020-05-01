class User
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_reader :name

  def initialize(username)
    @name = username
  end

  def to_param
    return @name
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

  def post_count
    return posts_hash['posts'].size
  end

  def posts_hash
    return JSON.parse(File.read("public/lj/#{@name}/#{@name}.json"))
  end

  def persisted?
    false
  end
end
