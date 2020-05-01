if Rails.env.production? == false
  require 'rubygems'
  require 'selenium-webdriver'
  require 'pathname'
  require 'fileutils'
  require 'time'
  require 'active_support/all'
end

module Downloader
  class ProxyError < StandardError; end
  class Chrome
    def self.create(headless: true, typ: 'desktop')
      # `killall chromium-browser > /dev/null 2>&1`
      # current_dir = File.expand_path(File.dirname(__FILE__))
      # datadir = Pathname(current_dir).dirname.to_s
      # datadir = Pathname(datadir).dirname.to_s
      # datadir = "#{datadir}/tmp/chrome_datadirs/"

      options = Selenium::WebDriver::Chrome::Options.new #/usr/bin/google-chrome
      options.add_argument('--ignore-certificate-errors')
      options.add_argument('--no-sandbox')
      options.add_argument('--disable-popup-blocking')
      options.add_argument('--disable-translate')
      options.add_argument('--disable-web-security')
      options.add_argument('--allow-running-insecure-content')
      options.add_argument('--disable-accelerated-video')
      options.add_argument('--disable-gpu')
      options.add_argument('--process-per-tab')

      options.add_argument('--disable-notifications')
      options.add_argument('--disable-desktop-notifications')
      options.add_argument('--disable-component-update')
      options.add_argument('--disable-datasaver-prompt')
      options.add_argument('--disable-hang-monitor')
      options.add_argument('--autoplay-policy=user-gesture-required')
      options.add_argument('--no-default-browser-check')

      options.add_argument('--disable-features=site-per-process') # Disables OOPIF
      options.add_argument('--blink-settings=imagesEnabled=false')

      options.add_argument('--disk-cache-size=2147483648')

      # options.add_argument('--disable-extensions')
      # options.add_argument('--proxy-server=socks5://localhost:7777')
      #   options.add_argument('--proxy-server=77.111.245.10:443')
      # options.add_argument("--user-data-dir=#{datadir}")

      if headless != false && ENV['NO_HEADLESS'] != '1'
        options.add_argument('--headless')
      end

      if ENV['PROXY']
        options.add_argument(%{--proxy-server=#{ENV['PROXY']}})
        options.add_argument(%{--user-agent="#{OPERA_USERAGENT}"})
      end

      return Selenium::WebDriver.for :chrome, options: options
    end
  end
end
