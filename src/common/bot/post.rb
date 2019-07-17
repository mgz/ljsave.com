require 'loofah'
require 'sanitize'
require "awesome_print"


class Post
    attr_reader :url, :title, :time
    def initialize(url)
        @url = url
    end
    
    def self.save_posts(urls)
        posts = []
        browsers = []
        # Parallel.each(urls, in_processes: 8, progress: "Saving #{urls.size} posts") do |url|
        urls.each do |url|
            post = Post.new(url)
            
            if File.exists?(post.downloaded_file_path)
                putsd "Skipping #{post.url}"
                
                html = Nokogiri::HTML(open(post.downloaded_file_path))
                post.init_title_and_time(html)
                
                posts << post
                next
            end
            
            # browser = browsers[Parallel.worker_number] || create_chrome(headless: true, typ: 'desktop')
            # browsers[Parallel.worker_number] ||= browser

            browser = create_chrome(headless: true, typ: 'desktop')

            begin
                post.save_page_with_expanded_comments(browser)
            rescue => e
                puts "#{e.inspect} for #{url}"
                # throw e
            end
            browser.quit
            posts << post
        end
        return posts
    end
    
    def save_page_with_expanded_comments(browser)
        putsd "Downloading #{@url}"
        browser.navigate.to(@url)
        # ap browser.manage.all_cookies
        # unless browser.manage.all_cookies.any?{|c| c[:name] == 'prop_opt_readability'}
        #     browser.manage.add_cookie(name: "prop_opt_readability", value: "1", expires: 10.days.from_now)
        #     browser.navigate.to(@url)
        # end

        if (checkbox = browser.find_elements(id: 'view-own').first) && checkbox.attribute('checked') != 'true'
            putsd 'Setting READABILITY mode'
            browser.execute_script("arguments[0].click();", checkbox)
        end
        
        contents = expand_all_comments_on_page(browser)

        page_count = browser.find_elements(class: 'b-pager-page').last&.text&.to_i || 1
        putsd "Post has #{page_count} pages"

        html = Nokogiri::HTML(contents)
        
        init_title_and_time(html)
        
        html.css('.b-pager')&.remove
        html.css('.b-xylem')[1]&.remove
        html.css('.b-xylem-cell')&.remove
        html.css('.b-singlepost-standout')&.remove
        html.css('footer')&.remove
        html.css('.b-discoverytimes-wrapper')&.remove
        html.css('.ljsale')&.remove
        html.css('.lj-recommended')&.remove


        if true && page_count > 1

            comments_html = html.at_css('#comments')
            (2..page_count).each do |page_num|
                browser.navigate.to(@url + "?page=#{page_num}")
                more_content = Nokogiri::HTML(expand_all_comments_on_page(browser)).at_css('#comments')
                
                # Remove pager
                more_content.css('.b-xylem')&.remove
                
                
                comments_html.add_child(more_content.inner_html)
            end
        end


        html.css("div[prev-next-nav]")&.remove
        html.css('.b-leaf-footer')&.remove
        contents = html.to_html
        save_page(contents)
    end
    
    def get_expand_links(browser)
        # putsd 'Finding expand links...'
        browser.manage.timeouts.implicit_wait = 0
        expand_links = browser.find_elements(css: '#comments .b-leaf-footer .b-leaf-actions-expandchilds a').select{|a|
            begin
                # putsd 'Checking link...'
                # a.text.downcase.in?(%w{expand развернуть}) && a.displayed?
                # a.displayed?
                true
            rescue Selenium::WebDriver::Error::StaleElementReferenceError
                putsd ' got exception...'
            end
        }
        
        links_at_depths = {}
        
        expand_links.each do |link|
            parent = link.find_element(xpath: '../../../../../..')
            if parent.attribute('style').present?
                margin_left = parent.style('margin-left')
            else
                margin_left = link.find_element(xpath: '../../../../../../..').style('margin-left')
            end

            depth = margin_left[/(\d+)/, 1].to_i / 30
            links_at_depths[depth] ||= []
            links_at_depths[depth] << link
        end
        return links_at_depths[links_at_depths.keys.min] || []
    end

    def expand_all_comments_on_page(browser)
        while browser.find_elements(css: '#comments.b-grove-loading').any?
            puts 'Still have preloader, waiting'
            sleep 0.3
        end
        while (links = get_expand_links(browser)).any?
            putsd "Got #{links.size} links to expand"
            Parallel.each(links, in_processes: 6) do |a|
                # putsd span.attribute('style')
                # a = span.find_element(css: 'a')
                # comment_id = a.attribute('onclick')[/'(\d+)'/, 1]
                # print "Expanding #{a.attribute('href')}..."
                begin
                    browser.execute_script("arguments[0].click();", a)

                    while a.displayed?
                        sleep 0.3
                    end
                rescue Selenium::WebDriver::Error::StaleElementReferenceError
                    # Element is gone, fine.
                rescue Errno::EPIPE, EOFError => e
                    putsd e
                end
                # putsd ' done.'
            end
        end
        
        putsd 'Everything expanded'
        return browser.page_source
    end
    
    def save_page(contents)
        # remove_scripts = Loofah::Scrubber.new do |node|
        #     if node.name == "script"
        #         node.remove
        #         Loofah::Scrubber::STOP # don't bother with the rest of the subtree
        #     end
        # end
        # contents = Loofah.document(contents).scrub!(remove_scripts).to_s
        # contents = Loofah.document(contents).scrub!(:prune).to_s
        # contents = Sanitize.clean(contents, :remove_contents => ['script'])
        
        
        doc = Nokogiri.HTML(contents)                            # Parse the document
        doc.css('script').remove                             # Remove <script>…</script>
        doc.xpath("//@*[starts-with(name(),'on')]").remove   # Remove on____ attributes
        doc.css('header').remove
        doc.css('.b-singlepost-addfriend-link')&.remove
        doc.css("div[suggestion-for-unlogged]")&.remove
        
        # Expand spoilers
        doc.css('.lj-spoiler').add_class('lj-spoiler-opened')
        
        contents = doc.to_html
        
        FileUtils.mkdir_p("cache/#{self.user.username}")
        File.open(downloaded_file_path, 'w') do |file|
            file << contents
        end
    end
    
    def user
        return User.new(@url[%r{://(.+?)\.}, 1])
    end
    
    def post_id
        return @url[%r{(\d+)\.html}, 1]
    end
    
    def init_title_and_time(html_doc)
        begin
            @title = html_doc.at_css('h1')&.text&.strip
            
            time_str = html_doc.at_css('time.published').text.strip
            @time = DateTime.strptime(time_str, '%Y-%m-%d %H:%M:%S')
        rescue => e
            puts "Error for #{self.url}:"
            puts e.inspect
        end
    end
    
    def downloaded_file_path
        return "cache/#{self.user.username}/#{self.post_id}.html"
    end
end