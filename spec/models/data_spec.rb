require 'rails_helper'

RSpec.describe "Mirrored data" do
  it "has all mirrored data" do
    users = User.downloaded_users
    
    expect(users.count).to eql(20)
    
    total_post_count = users.map{|u| u.posts_hash['posts'].size}.sum
    expect(total_post_count).to eql(54904)
  end
end