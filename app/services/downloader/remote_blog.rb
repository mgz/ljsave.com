require 'nokogiri'
require 'open-uri'
require 'parallel'
require 'active_support/all'

module Downloader
  class RemoteBlog
    attr_reader :username, :httpd_port
    
    def initialize(username)
      @username = username
    end
    
    def self.mirror_post(url)
      post = RemotePost.new(url)
      blog = post.blog
      blog.with_running_httpd do
        post.mirror
      end
    end
    
    def create_mirror_dir
      FileUtils.mkdir_p("#{out_dir}/#{@username}_files")
    end
    
    def create_cache_dir
      FileUtils.mkdir_p(RemoteBlog.cached_posts_dir)
    end
    
    def with_running_httpd
      start_httpd
      begin
        yield
      ensure
        stop_httpd
      end
    end
    
    def start_httpd
      @httpd_port = RemoteBlog.get_free_port
      puts "Starting httpd:#{@httpd_port}..."
      @httpd_server_process = Process.spawn("cd #{RemoteBlog.cached_posts_dir} && ruby -run -e httpd . -p #{@httpd_port} >/dev/null 2>/dev/null", :pgroup => true)
      sleep 3
    end
    
    def stop_httpd
      Process.kill('TERM', -Process.getpgid(@httpd_server_process))
    end
    
    def load_assets(posts)
      http_port = RemoteBlog.get_free_port
      putsd "Starting http server on port #{http_port}..."
      create_mirror_dir
      ensure_httpd_started
      
      Parallel.each(posts, in_processes: 8, progress: "Mirroring #{posts.size} HTMLs") do |post|
        url = "http://localhost:#{http_port}/#{post.user.name}/#{File.basename(post.cached_file_path)}"
        putsd url
        `wget -q -nv --timeout=2 -P #{RemoteBlog.out_dir}/#{@username}_files --page-requisites --no-cookies --no-host-directories --span-hosts -E --wait=0 --execute="robots = off"  --convert-links #{url}  >/dev/null 2>/dev/null`
      end
    end
    
    def create_index_file(posts)
      years_and_posts = Hash.new { |h, k| h[k] = [] }
      posts.each do |post|
        next unless post.title.present?
        next unless post.time.present?
        years_and_posts[post.time.year] << post
      end
      
      create_mirror_dir
      
      File.write("#{out_dir}/#{@username}.json", {
        posts: posts.map(&:to_json),
        years: years_and_posts
      }.to_json)
    end
    
    def rebuild_index_file(cached: true)
      posts = get_posts(cached: cached)
      create_index_file(posts)
    end
    
    def cached_posts_dir
      return RemoteBlog.cached_posts_dir + "#{@username}/"
    end
    
    def self.cached_posts_dir
      prefix = Rails.env.test? ? 'test' : ''
      return "scraped/#{prefix}cache/"
    end
    
    def out_dir
      prefix = Rails.env.test? ? 'test' : ''
      return "public/#{prefix}lj/#{@username}/"
    end
    
    def self.get_free_port
      port = 5012
      while port < 7000
        if RemoteBlog.port_open?(port)
          port += 1
        else
          return port
        end
      end
    end
    
    def self.port_open?(port)
      system("lsof -i:#{port}", out: '/dev/null')
    end
    
    def mirror
      posts = get_posts(cached: ENV['USE_CACHE'] == '1')
      putsd "Found #{posts.size} posts"
      
      with_running_httpd do
        mirror_posts(posts)
      end
      create_index_file(posts)
    end
    
    private
    
    def mirror_posts(posts)
      Parallel.each(posts, in_processes: 8, progress: "Mirroring #{posts.size} HTMLs") do |post|
        next if post.cached? && ENV['REMIRROR'] != '1'
        puts "Will mirror #{post}"
        begin
          post.mirror
        rescue => e
          puts e
          retry
        end
      end
    end
    
    def get_date_range
      start_year = 2001
      start_month = 1
      
      end_year = Date.today.year
      end_month = Date.today.month
      
      return start_year, start_month, end_year, end_month
      
      # "https://www.livejournal.com/view/?type=month&user=#{@username}&y=$year&m=$month"
    end
    
    def get_posts(cached: false)
      if cached && File.exists?(cached_posts_dir + '/_post_urls.txt')
        posts = File.open(cached_posts_dir + '/_post_urls.txt').readlines.map { |l| RemotePost.new(l.strip, blog: self) }
        return posts
      end
      
      start_year, start_month, end_year, end_month = get_date_range
      
      years_and_months = []
      
      (start_year..end_year).each do |year|
        (1..12).each do |month|
          next if year == end_year && month > end_month
          years_and_months << [year, month]
        end
      end
      
      results = Parallel.map(years_and_months, in_threads: 1) do |year, month|
        get_posts_from_archive_page(year, month)
      end
      
      posts = results.compact.flatten
      FileUtils.mkdir_p(cached_posts_dir)
      File.open(cached_posts_dir + '/_post_urls.txt', 'w').write(posts.map { |po| po.url }.join("\n"))
      return posts
    end
    
    def get_posts_from_archive_page(year, month)
      html = Nokogiri::HTML(read_url("https://#{@username}.livejournal.com/#{year}/#{sprintf('%02d', month)}/"))
      urls = html.css('a').select { |a| a.attribute('href')&.value =~ %r{://#{@username}.livejournal.com/\d+.html} }.map { |a| a.attribute('href').value }
      putsd "    #{urls.size} for #{year}.#{month}"
      return urls.map { |u| RemotePost.new(u.strip, blog: self) }
    end
  end
end