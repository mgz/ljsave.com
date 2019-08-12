require 'rubygems'
require 'selenium-webdriver'
require "net/http"
require "uri"
require 'active_support/all'

require_relative 'chrome.rb'
require_relative 'user.rb'
require_relative 'post.rb'
require_relative 'functions.rb'

$stdout.sync = true

if ENV['CLEAR_CACHE'] == '1'
  FileUtils.rm_rf('cache')
end

if (post_url = ARGV[0]) && post_url.start_with?('https://')
  BROWSER = create_chrome(headless: true, typ: 'desktop')
  putsd "Fetching post #{post_url}"
  # post = Post.new('https://palaman.livejournal.com/410686.html')
  post = Post.new(post_url)
  post.download_and_save
elsif ('browser' == ARGV[0])
  BROWSER = create_chrome(headless: true, typ: 'desktop')
  sleep 10_000_000
elsif (username = ARGV[0])
  user = User.new(username)
  putsd "User: #{user.username}"
  post_urls = user.get_post_urls(cached: ENV['USE_CACHE'] == '1')
  putsd "Found #{post_urls.size} posts"

  unless ENV['NO_SAVE_POSTS'] == '1'
    # posts = Post.save_posts(post_urls[-5, 3])
    posts = RemotePost.save_posts(post_urls)
  end
  
  unless ENV['NO_WGET'] == '1'
    user.load_assets(posts)
    user.create_index_file(posts)
  end
end

# post_urls = user.get_post_urls

# putsd "Found #{post_urls} posts"


# putsd user.get_post_urls_from_archive_page(2018, 11)


# BROWSER.navigate.to 'https://palaman.livejournal.com/2019/06/'
#
# BROWSER.find_elements(css: '.viewsubjects a').each do |link|
#     link.click
#     break
# end
#
# Bot.expand_all_comments_on_page

puts 'Sleeping'
sleep 5
# sleep 1000

