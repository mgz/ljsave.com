module Bot
    def self.expand_all_comments_on_page
        while (span = BROWSER.find_elements(css: '.comment-meta span').detect{|s| s.attribute('id').start_with?('expand_') && s.attribute('style') != 'display: none;'})
            # putsd span.attribute('style')
            a = span.find_element(css: 'a')
            comment_id = a.attribute('onclick')[/'(\d+)'/, 1]
            putsd "Expanding #{comment_id}..."
            BROWSER.execute_script("arguments[0].click();", a)
            
            wait = Selenium::WebDriver::Wait.new(:timeout => 10)
            wait.until {BROWSER.find_element id: "collapse_#{comment_id}"}
            putsd '    Done.'
            sleep 1
        end
        putsd 'Everything expanded'
    end
end

def putsd(*args)
    if ENV['DEBUG_LOG'] == '1'
        puts args
    end
end

OPERA_USERAGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.87 Safari/537.36 OPR/37.0.2178.31'

def read_url(url, opts: {})
    if (proxy = ENV['PROXY'])
        proxy = "http://#{proxy}" unless proxy.start_with?('http://')
        opts[:proxy] = URI.parse(proxy)
        opts['User-Agent'] = OPERA_USERAGENT
    end
    
    return open(url, opts).read
end