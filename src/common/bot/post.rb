require 'loofah'
require 'sanitize'

class Post
    def initialize(url)
        @url = url
    end
    
    def save_page_with_expanded_comments(browser)
        browser.navigate.to(@url)
        
        if (checkbox = browser.find_element(id: 'view-own')).attribute('checked') != 'true'
            puts 'Setting READABILITY mode'
            checkbox.click
        end
        
        contents = expand_all_comments_on_page(browser)

        page_count = browser.find_elements(class: 'b-pager-page').last&.text&.to_i || 1
        puts "Post has #{page_count} pages"

        html = Nokogiri::HTML(contents)
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

    def expand_all_comments_on_page(browser)
        while (a = browser.find_elements(css: '#comments a').detect{|a|
                begin
                    a.displayed? && a.text.downcase.in?(%w{expand развернуть})
                rescue Selenium::WebDriver::Error::StaleElementReferenceError
                end
        })
            # puts span.attribute('style')
            # a = span.find_element(css: 'a')
            # comment_id = a.attribute('onclick')[/'(\d+)'/, 1]
            print "Expanding #{a.attribute('href')}..."
            browser.execute_script("arguments[0].click();", a)
        
            begin
                while a.displayed?
                    sleep 0.1
                end
            rescue Selenium::WebDriver::Error::StaleElementReferenceError
                # Element is gone, fine.
            end
            puts ' done.'
        end
        puts 'Everything expanded'
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
        contents = doc.to_html
        
        FileUtils.mkdir_p("out/#{self.user.username}")
        File.open("out/#{self.user.username}/#{self.post_id}.html", 'w') do |file|
            file << contents
        end
    end
    
    def user
        return User.new(@url[%r{://(.+?)\.}, 1])
    end
    
    def post_id
        return @url[%r{(\d+)\.html}, 1]
    end
end