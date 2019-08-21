
namespace :scraper do
  desc "Mirror a post"
  task :mirror_post => :environment do
    # require File.join(Rails.root, 'app', 'services', 'downloader', 'post_downloader.rb')
  
  
    url = ENV['url']
    # puts "url: #{url}"
    Downloader::RemoteBlog.mirror_post(url)
  end
  
  desc "Download missing posts"
  task :download => :environment do
    username = ENV['username']
    
    blog = Downloader::RemoteBlog.new(username)
    blog.mirror
  end
end
