require 'test_helper'
class PostTest < ActiveSupport::TestCase
  test 'Replace links' do
    post = Post.new(id: 1, username: 'aa')
    
    html = 'тест <a href="http://alexandrov-g.livejournal.com/107620.html?#cutid1" target="_self">http://alexandrov-g.livejournal.com/107620.html?#cutid1</a>'
    res = post.send(:replace_links_to_other_downloaded_blogs!, html: html, downloaded_user: User.new('alexandrov-g'))
    assert_equal 'тест <a href="/user/alexandrov-g/107620?#cutid1" target="_self">http://alexandrov-g.livejournal.com/107620.html?#cutid1</a>', res
  end
end