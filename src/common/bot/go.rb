require 'rubygems'
require 'selenium-webdriver'
require "net/http"
require "uri"
require 'httparty'
require 'active_support/all'

require_relative 'chrome.rb'
require_relative 'user.rb'
require_relative 'post.rb'
require_relative 'functions.rb'

$stdout.sync = true

BROWSER = create_chrome(headless: false, typ: 'desktop')


user = User.new(ARGV[0])

# puts "User: #{user.username}"

if (post_url = ARGV[0]) && post_url.start_with?('https://')
    puts "Fetching post #{post_url}"
    # post = Post.new('https://palaman.livejournal.com/410686.html')
    post = Post.new(post_url)
    post.save_page_with_expanded_comments(BROWSER)
end

# post_urls = user.get_post_urls

# puts "Found #{post_urls} posts"


# puts user.get_post_urls_from_archive_page(2018, 11)


# BROWSER.navigate.to 'https://palaman.livejournal.com/2019/06/'
#
# BROWSER.find_elements(css: '.viewsubjects a').each do |link|
#     link.click
#     break
# end
#
# Bot.expand_all_comments_on_page


# sleep 100

