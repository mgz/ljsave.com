
namespace :scraper do
  desc "Mirror a post"
  task :mirror_post => :environment do
    # require File.join(Rails.root, 'app', 'services', 'downloader', 'post_downloader.rb')
  
  
    url = ENV['url']
    puts "url: #{url}"
    post = PostDownloader.new(url)
    post.mirror
  end
  
  desc "Download missing posts"
  task :download => :environment do
    username = ENV['username']
    
    blog = Blog.new(username)
    blog.mirror
  end
end
