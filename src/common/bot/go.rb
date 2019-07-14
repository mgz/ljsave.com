require 'rubygems'
require 'selenium-webdriver'
require "net/http"
require "uri"
require 'httparty'
require 'active_support/all'

require_relative 'chrome.rb'

BROWSER = create_chrome(headless: false, typ: 'desktop')

BROWSER.navigate.to 'https://palaman.livejournal.com/2019/06/'

expand_links = BROWSER.find_elements(css: '.viewsubjects a')
expand_links.each do |link|
    link.click
    while (span = BROWSER.find_elements(css: '.comment-links span').detect{|s| s.attribute('id').start_with?('expand_')})
        a = span.find_element(css: 'a')
        comment_id = a.attribute('onclick')[/'(\d+)'/, 1]
        puts "Expanding #{comment_id}..."
        BROWSER.execute_script("arguments[0].click();", a)
        sleep 1
    end
end
