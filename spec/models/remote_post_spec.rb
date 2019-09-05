require 'rails_helper'

POST_URL = 'https://maagz.livejournal.com/965.html'
# ENV['NO_HEADLESS'] = '1'

def load_url
  expect(ENV['PROXY']).to be_truthy
  url = 'https://maagz.livejournal.com/965.html'
  browser.navigate.to url
end

def in_readability_mode?
  checkbox = browser.find_elements(id: 'view-own').first
  return checkbox.attribute('checked') == 'true'
end

def has_18_warning?
  return browser.find_elements(class: 'b-msgsystem-warningbox-confirm').first != nil
end

def validate_local_html(filename)
  expect(File.exists?(filename)).to be true
  html = File.read(filename)
  doc = Nokogiri::HTML(html)
  
  found_comments = doc.css('.b-tree-twig')
  expect(found_comments.count).to eql(37)
  
  (1..37).to_a.each do |idx|
    expect(html).to match(/comm #{idx}/)
  end
end

RSpec.describe Downloader::RemotePost do
  
  describe "post #{POST_URL}" do
    let!(:post) { Downloader::RemotePost.new(POST_URL) }
    let!(:browser) { post.send(:prepare_browser) }
    
    it "enters READABILITY mode" do
      post.send(:accept_18_years_warning)
      
      expect(in_readability_mode?).to be false
      post.send(:click_readability_checkbox)
      expect(in_readability_mode?).to be true
    end
    
    it "enters 18+ mode" do
      expect(has_18_warning?).to be true
      post.send(:accept_18_years_warning)
      expect(has_18_warning?).to be false
    end
    
    it "detects number of comment pages" do
      post.send(:accept_18_years_warning)
      post.send(:click_readability_checkbox)
      
      page_count = post.send(:determine_page_count)
      expect(page_count).to eql(2)
    end

    it "gets title and time" do
      post.send(:accept_18_years_warning)
      post.send(:click_readability_checkbox)

      post.send(:init_title_and_time)
      
      expect(post.title).to eql 'test old'
      expect(post.time.to_s).to eql '2019-08-21T12:47:00+00:00'
    end
    
    it "downloads to cache" do
      filename = post.send(:cached_file_path)
      File.delete(filename) if File.exists?(filename)
      
      post.send(:download_expand_comments_and_save_cache)
      expect(post.comment_count).to eql(37)

      validate_local_html(filename)
    end
  end

  it "mirrors with assets" do
    post = Downloader::RemotePost.new(POST_URL)
    filename = "#{post.blog.out_dir}/#{post.blog.username}_files/#{post.blog.username}/965.html"
    File.delete(filename) if File.exists?(filename)

    Downloader::RemoteBlog.mirror_post(POST_URL)
  
    validate_local_html(filename)
  end

  
end
