require 'rails_helper'

RSpec.describe Post, type: :model do
  context "Content mangling" do
    it "replaces links to downloaded blogs" do
      post = Post.new(id: 1, username: 'aa')
  
      html = 'тест <a href="http://alexandrov-g.livejournal.com" target="_self">http://alexandrov-g.livejournal.com/107620.html?#cutid1</a>'
      post_parser = PostParser.new(post)
      res = post_parser.send(:replace_links_to_other_downloaded_blogs!, html: html, downloaded_user: User.new('alexandrov-g'))
      expect(res).to eql 'тест <a href="/user/alexandrov-g" target="_self">http://alexandrov-g.livejournal.com/107620.html?#cutid1</a>'
    end

    it "replaces links to downloaded posts" do
      post = Post.new(id: 1, username: 'aa')
  
      html = 'тест <a href="http://alexandrov-g.livejournal.com/107620.html" target="_self">http://alexandrov-g.livejournal.com/107620.html?#cutid1</a>'
      post_parser = PostParser.new(post)
      res = post_parser.send(:replace_links_to_other_downloaded_blogs!, html: html, downloaded_user: User.new('alexandrov-g'))
      expect(res).to eql 'тест <a href="/user/alexandrov-g/107620" target="_self">http://alexandrov-g.livejournal.com/107620.html?#cutid1</a>'
    end

    it "replaces links to downloaded blogs with params" do
      post = Post.new(id: 1, username: 'aa')
  
      html = 'тест <a href="http://alexandrov-g.livejournal.com/107620.html?#cutid1" target="_self">http://alexandrov-g.livejournal.com/107620.html?#cutid1</a>'
      post_parser = PostParser.new(post)
      res = post_parser.send(:replace_links_to_other_downloaded_blogs!, html: html, downloaded_user: User.new('alexandrov-g'))
      expect(res).to eql 'тест <a href="/user/alexandrov-g/107620?#cutid1" target="_self">http://alexandrov-g.livejournal.com/107620.html?#cutid1</a>'
    end
  end
end
