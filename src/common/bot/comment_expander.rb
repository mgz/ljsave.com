require "awesome_print"

class CommentExpander
  def self.get_expand_links(browser)
    putsd 'Finding expand links...'
    browser.manage.timeouts.implicit_wait = 0
    expand_links = browser.find_elements(css: '.b-leaf-footer .b-leaf-actions-expandchilds a')
    expand_links += browser.find_elements(css: '.b-leaf-collapsed .b-leaf-header .b-leaf-actions-expand a')
    expand_links += browser.find_elements(css: '.b-leaf-seemore-expand a')
    
    putsd "    Found #{expand_links.size} links"
    
    links_at_depths = {}
    
    expand_links.each do |link|
      begin
        parent = link.find_element(xpath: '../../../../../..')
        if parent.attribute('style').present?
          margin_left = parent.style('margin-left')
        else
          margin_left = link.find_element(xpath: '../../../../../../..').style('margin-left')
        end
        
        depth = margin_left[/(\d+)/, 1].to_i / 30
        links_at_depths[depth] ||= []
        links_at_depths[depth] << link
      rescue Selenium::WebDriver::Error::StaleElementReferenceError
        # Link is gone
      end
    end
    return links_at_depths[links_at_depths.keys.min] || []
  end
  
  def self.expand_all_comments_on_page(browser)
    slept_seconds = 0.0
    while browser.find_elements(css: '#comments.b-grove-loading').any? || browser.find_elements(css: 'div.b-grove.b-grove-hover').any?
      putsd 'Still have preloader, waiting'
      slept_seconds += 0.3
      sleep 0.3
      break if slept_seconds > 10
    end
    
    links_clicked_times = Hash.new(0)
    
    putsd "Post has #{browser.find_elements(class: 'b-tree-twig').size} comments"
    
    while (links = get_expand_links(browser)).any?
      putsd "Got #{links.size} links to expand"
      
      links.each do |link|
        begin
          href = link.attribute('href')
          if links_clicked_times[href] > 5
            putsd "    Clicked #{href} too many times, exiting..."
            # sleep 1000
            return browser.page_source
          end
          putsd "    Clicking #{href}..."
          # link.click
          browser.execute_script("arguments[0].click();", link)
          links_clicked_times[href] += 1
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
      
      
      sleep 1
      
      # Parallel.each(links, in_threads: 6) do |a|
      #     # putsd span.attribute('style')
      #     # a = span.find_element(css: 'a')
      #     # comment_id = a.attribute('onclick')[/'(\d+)'/, 1]
      #     putsd "Expanding ..."
      #     begin
      #         a.click
      #         # browser.execute_script("arguments[0].click();", a)
      #
      #         times_slept = 0
      #         while a.displayed?
      #             sleep 0.3
      #             times_slept += 1
      #             raise 'Sleeping too long' if times_slept > 10
      #         end
      #     rescue Selenium::WebDriver::Error::ElementClickInterceptedError
      #         putsd '    Click intercepted'
      #     rescue Selenium::WebDriver::Error::StaleElementReferenceError
      #         # Element is gone, fine.
      #         putsd '    Element gone'
      #     # rescue Errno::EPIPE, EOFError => e
      #     #     putsd e
      #     end
      #     # putsd ' done.'
      # end
    end
    
    putsd '    * Everything expanded'
    return browser.page_source
  end
end