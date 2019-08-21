class Post
  attr_reader :id, :user
  def initialize(id:, username:)
    @id = id
    @user = User.new(username)
  end
end