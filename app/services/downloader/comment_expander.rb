require "awesome_print"
module Downloader
  class CannotExpandLinkError < StandardError
  
  end
  
  class CommentExpander
    def initialize(browser)
      @browser = browser
    end
    
    def expand_all_comments_on_page
      wait_for_page_to_load
      
      @links_clicked_times = Hash.new(0)
      
      putsd "Post has #{@browser.find_elements(class: 'b-tree-twig').size} comments"
      
      while (links = get_links_to_click_and_expand).any?
        putsd "Got #{links.size} links to expand"
        
        links.each do |link|
          click_link(link)
        end
        sleep 1
      end
      putsd '    * Everything expanded'
      ensure
        return @browser.page_source
    end
    
    private
    def get_links_to_click_and_expand
      putsd 'Finding expand links...'
      links = ExpandLink.find_on_page(@browser)
      putsd "    Found #{links.size} links"
      return ExpandLink.top_level_links(links)
    end
    
    def click_link(link)
      begin
        if @links_clicked_times[link.href] > 5
          putsd "    Clicked #{link.href} too many times, exiting..."
          raise CannotExpandLinkError.new(link.href)
        end
        putsd "    Clicking #{link.href}..."
        link.click
        @links_clicked_times[link.href] += 1
        sleep 1
      rescue Selenium::WebDriver::Error::ElementClickInterceptedError
        putsd '    Click intercepted'
      rescue Selenium::WebDriver::Error::StaleElementReferenceError
        # Element is gone, fine.
        putsd '    Element gone'
      rescue Selenium::WebDriver::Error::ElementNotInteractableError
        putsd '    Element not interactable'
      end
    end
    
    def wait_for_page_to_load
      slept_seconds = 0.0
      delta = 0.5
      while page_still_loading?
        putsd 'Still have preloader, waiting'
        slept_seconds += delta
        sleep delta
        if slept_seconds > 5
          @browser.execute_script('window.location.reload()')
        end
        break if slept_seconds > 10
      end
    end
    
    def page_still_loading?
      return @browser.find_elements(css: '#comments.b-grove-loading').any? || @browser.find_elements(css: 'div.b-grove.b-grove-hover').any?
    end
    
  end
end