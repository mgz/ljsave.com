require 'nokogiri'
require 'open-uri'
require 'parallel'
require 'active_support/all'


require_relative 'functions.rb'
require_relative 'post.rb'

class User
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
    
    def get_post_urls(cached: false)
        if cached && File.exists?(cached_posts_dir + '/_post_urls.txt')
            return File.open(cached_posts_dir + '/_post_urls.txt').readlines.map{|l| l.strip}#.take(20)
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
        File.open(cached_posts_dir + '/_post_urls.txt', 'w').write(post_urls.join("\n"))
        return post_urls
    end
    
    def get_post_urls_from_archive_page(year, month)
        html = Nokogiri::HTML(read_url("https://#{@username}.livejournal.com/#{year}/#{sprintf('%02d', month)}/"))
        urls =  html.css('a').select{|a| a.attribute('href')&.value =~ %r{://#{@username}.livejournal.com/\d+.html}}.map{|a| a.attribute('href').value}
        putsd "    #{urls.size} for #{year}.#{month}"
        return urls
    end

    def load_assets(posts)
        http_port = 5011
        FileUtils.mkdir_p("#{User.out_dir}/#{@username}_files")
        `pkill -f "p #{http_port}"`
        http_server_thread = Process.spawn "cd #{cached_posts_dir}/.. && ruby -run -e httpd . -p #{http_port}  >/dev/null 2>/dev/null", pgroup: true
        sleep 3
        
        
        Parallel.each(posts, in_processes: 8, progress: "Mirroring #{posts.size} HTMLs") do |post|
            url = "http://localhost:#{http_port}/#{post.user.username}/#{File.basename(post.downloaded_file_path)}"
            putsd url
            # `wget -c --timeout=2 -q -P out/files -nv --page-requisites --no-cookies --no-host-directories --span-hosts -E --wait=0 --execute="robots = off"  --convert-links #{url} >/dev/null 2>/dev/null `
            `wget -nc -q -nv --timeout=2 -P #{User.out_dir}/#{@username}_files --page-requisites --no-cookies --no-host-directories --span-hosts -E --wait=0 --execute="robots = off"  --convert-links #{url}  >/dev/null 2>/dev/null`
            # FileUtils.rm(html_file)
        end

        # `wget -c --timeout=2 -q -P out/files -nv --page-requisites --no-cookies --no-host-directories --span-hosts -E --wait=0 --execute="robots = off"  --convert-links -i cache/url_list.txt >/dev/null 2>/dev/null`
        # `cat cache/url_list.txt | parallel --gnu "wget -c --timeout=2 -q -P out/files -nv --page-requisites --no-cookies --no-host-directories --span-hosts -E --wait=0 --execute="robots = off"  --convert-links {} >/dev/null 2>/dev/null"`
        # `xargs -n 1 -P 4 -i wget -c --timeout=2 -q -P out/files -nv --page-requisites --no-cookies --no-host-directories --span-hosts -E --wait=0 --execute="robots = off"  --convert-links {} >/dev/null 2>/dev/null < cache/url_list.txt`


        Process.kill(9, -Process.getpgid(http_server_thread))
    end
    
    def create_index_file(posts)
        page_title = "#{@username}.livejournal.com"
        user_name = @username
        
        
        years_and_posts = Hash.new{|h, k| h[k] = []}
        posts.each do |post|
            next unless post.title.present?
            next unless post.time.present?
            years_and_posts[post.time.year] << post
        end
        
        builder = Nokogiri::HTML::Builder.new do |doc|
            doc.div.years do
                years_and_posts.keys.sort.each do |year|
                    doc.div.card(class: 'mb-5') do
                        doc.h5(class: 'card-header') do
                            doc.text year
                        end
                        doc.ul(class: 'list-group list-group-flush') do
                            years_and_posts[year].each do |post|
                                doc.li(class: 'list-group-item d-flex justify-content-between align-items-center') do
                                    doc.a(href: "#{user_name}_files/#{post.user.username}/#{post.post_id}.html") do
                                        doc.text post.title
                                    end
                                    if post.time
                                        doc.a(href: post.url, target: '_blank') do
                                            doc.span(class: 'badge badge-white') do
                                                doc.text post.time.strftime('%d %b %Y')
                                                doc.text ' '
                                                doc.small do
                                                    doc.text post.time.strftime('%H:%M')
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        username = @username
        
        body = builder.to_html
        
        File.write("#{User.out_dir}/#{@username}.html", ERB.new(File.read(File.expand_path(File.dirname(__FILE__) + '/index.html.erb'))).result(binding))
        FileUtils.cp(File.expand_path(File.dirname(__FILE__) + '/bootstrap.min.css'), "#{User.out_dir}/#{@username}_files/")
    end
    
    def rebuild_index_file(cached: true)
        posts = get_post_urls(cached: cached).map do |post_url|
            post = Post.new(post_url)
            post.load_from_cached_file
            post
        end
        
        create_index_file(posts)
    end

    def cached_posts_dir
        parent = File.expand_path("..", Dir.pwd)
        parent = File.expand_path("..", parent)
        parent = File.expand_path("..", parent)
        return "#{parent}/cache/#{@username}"
    end
    
    def self.out_dir
        parent = File.expand_path("..", Dir.pwd)
        parent = File.expand_path("..", parent)
        parent = File.expand_path("..", parent)
        return "#{parent}/out"
    end
end