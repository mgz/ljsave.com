require 'nokogiri'
require 'open-uri'
require 'parallel'
require 'active_support/all'

require_relative 'functions.rb'

class Blog
  attr_reader :username
  
  def initialize(username)
    @username = username
  end
  
  def get_date_range
    start_year = 2001
    # start_year = 2018
    start_month = 1
    
    end_year = Date.today.year
    end_month = Date.today.month
    
    return start_year, start_month, end_year, end_month
    
    # "https://www.livejournal.com/view/?type=month&user=#{@username}&y=$year&m=$month"
  end
  
  def get_posts(cached: false)
    if cached && File.exists?(cached_posts_dir + '/_post_urls.txt')
      posts = File.open(cached_posts_dir + '/_post_urls.txt').readlines.map { |l| PostDownloader.new(l.strip) }
      posts.each{|po| po.load_from_cached_file}
      return posts
    end
    
    post_urls = []
    start_year, start_month, end_year, end_month = get_date_range
    
    years_and_months = []
    
    (start_year..end_year).each do |year|
      (1..12).each do |month|
        next if year == end_year && month > end_month
        years_and_months << [year, month]
      end
    end
    
    results = Parallel.map(years_and_months, in_threads: 16) do |year, month|
      # putsd "Now at #{year}.#{month}"
      get_post_urls_from_archive_page(year, month)
    end
    
    post_urls = results.compact.flatten
    FileUtils.mkdir_p(cached_posts_dir)
    File.open(cached_posts_dir + '/_post_urls.txt', 'w').write(post_urls.join("\n"))
    return post_urls.map { |l| PostDownloader.new(l.strip) }
  end
  
  def get_post_urls_from_archive_page(year, month)
    html = Nokogiri::HTML(read_url("https://#{@username}.livejournal.com/#{year}/#{sprintf('%02d', month)}/"))
    urls = html.css('a').select { |a| a.attribute('href')&.value =~ %r{://#{@username}.livejournal.com/\d+.html} }.map { |a| a.attribute('href').value }
    putsd "    #{urls.size} for #{year}.#{month}"
    return urls
  end
  
  def create_mirror_dir
    FileUtils.mkdir_p("#{out_dir}/#{@username}_files")
  end
  
  def create_cache_dir
    FileUtils.mkdir_p(Blog.cached_posts_dir)
  end
  
  def start_httpd
    port = Blog.get_free_port
    puts "Starting httpd:#{port}..."
    # `cd scraped/cache && ruby -run -e httpd . -p #{Blog.get_free_port}  >/dev/null 2>/dev/null`
    @httpd_server_process = Process.spawn("cd scraped/cache && ruby -run -e httpd . -p #{port} >/dev/null 2>/dev/null",  :pgroup => true)
    
    
    # puts "Started process #{@httpd_server_process}"
    sleep 3
    return port
  end
  
  def stop_httpd
    # @httpd_server_process.stop
    # `kill #{@httpd_server_process}`
    Process.kill('TERM', -Process.getpgid(@httpd_server_process))
    # Process.wait @httpd_server_process
  end
  
  def load_assets(posts)
    http_port = Blog.get_free_port
    putsd "Starting http server on port #{http_port}..."
    create_mirror_dir
    # `pkill -f "p #{http_port}"`
    ensure_httpd_started
    
    Parallel.each(posts, in_processes: 8, progress: "Mirroring #{posts.size} HTMLs") do |post|
      url = "http://localhost:#{http_port}/#{post.user.name}/#{File.basename(post.downloaded_file_path)}"
      putsd url
      # `wget -c --timeout=2 -q -P out/files -nv --page-requisites --no-cookies --no-host-directories --span-hosts -E --wait=0 --execute="robots = off"  --convert-links #{url} >/dev/null 2>/dev/null `
      `wget -q -nv --timeout=2 -P #{Blog.out_dir}/#{@username}_files --page-requisites --no-cookies --no-host-directories --span-hosts -E --wait=0 --execute="robots = off"  --convert-links #{url}  >/dev/null 2>/dev/null`
      # FileUtils.rm(html_file)
    end
    
    # `wget -c --timeout=2 -q -P out/files -nv --page-requisites --no-cookies --no-host-directories --span-hosts -E --wait=0 --execute="robots = off"  --convert-links -i cache/url_list.txt >/dev/null 2>/dev/null`
    # `cat cache/url_list.txt | parallel --gnu "wget -c --timeout=2 -q -P out/files -nv --page-requisites --no-cookies --no-host-directories --span-hosts -E --wait=0 --execute="robots = off"  --convert-links {} >/dev/null 2>/dev/null"`
    # `xargs -n 1 -P 4 -i wget -c --timeout=2 -q -P out/files -nv --page-requisites --no-cookies --no-host-directories --span-hosts -E --wait=0 --execute="robots = off"  --convert-links {} >/dev/null 2>/dev/null < cache/url_list.txt`
    
    
    # Process.kill(9, -Process.getpgid(http_server_thread))
  end
  
  def create_index_file(posts)
    page_title = "#{@username}.livejournal.com"
    
    years_and_posts = Hash.new { |h, k| h[k] = [] }
    posts.each do |post|
      next unless post.title.present?
      next unless post.time.present?
      years_and_posts[post.time.year] << post
    end
    
    # builder = Nokogiri::HTML::Builder.new(:encoding => 'UTF-8') do |doc|
    #   doc.div.years do
    #     years_and_posts.keys.sort.each do |year|
    #       doc.div.card(class: 'mb-5') do
    #         doc.h5(class: 'card-header') do
    #           doc.text year
    #         end
    #         doc.ul(class: 'list-group list-group-flush') do
    #           years_and_posts[year].each do |post|
    #             doc.li(class: 'list-group-item d-flex justify-content-between align-items-center') do
    #               doc.a(href: "/lj/#{post.user.name}/#{post.user.username}_files/#{post.user.name}/#{post.post_id}.html") do
    #                 doc.text post.title
    #               end
    #               if post.time
    #                 doc.a(href: post.url, target: '_blank') do
    #                   doc.span(class: 'badge badge-white') do
    #                     doc.text post.time.strftime('%d %b %Y')
    #                     doc.text ' '
    #                     doc.small do
    #                       doc.text post.time.strftime('%H:%M')
    #                     end
    #                   end
    #                 end
    #               end
    #             end
    #           end
    #         end
    #       end
    #     end
    #   end
    # end
    
    # name = @username
    # body = builder.to_html
    # File.write("#{User.out_dir}/#{@username}.html", ERB.new(File.read(File.expand_path(File.dirname(__FILE__) + '/index.html.erb'))).result(binding))
    
    File.write("#{Blog.out_dir}/#{@username}.json", {
      posts: posts.map(&:to_json),
      years: years_and_posts
    }.to_json)
  end
  
  def rebuild_index_file(cached: true)
    posts = get_posts(cached: cached).map do |post|
      post.load_from_cached_file
      post
    end
    
    create_index_file(posts)
  end
  
  def cached_posts_dir
    return "scraped/cache/#{@username}"
  end
  
  def out_dir
    return "public/lj/#{@username}/"
  end
  
  def self.get_free_port
    # return 5012
    # require 'socket'
    port = 5012
    while port < 7000
      if Blog.port_open?(port)
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

    port = start_httpd

    Parallel.each(posts, in_processes: 8, progress: "Mirroring #{posts.size} HTMLs") do |post|
      next if post.downloaded? && ENV['REMIRROR'] != '1'
      puts "Will mirror #{post}"
      begin
        post.mirror(port)
      rescue => e
        puts e
        retry
      end
    end
    stop_httpd
  end
end