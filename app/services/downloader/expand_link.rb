module Downloader
  class ExpandLink
    def initialize(html_element, browser)
      @elem = html_element
      @browser = browser
    end
    
    def self.find_on_page(browser)
      browser.manage.timeouts.implicit_wait = 0
      expand_links = browser.find_elements(css: '.b-leaf-footer .b-leaf-actions-expandchilds a')
      expand_links += browser.find_elements(css: '.b-leaf-collapsed .b-leaf-header .b-leaf-actions-expand a')
      expand_links += browser.find_elements(css: '.b-leaf-seemore-expand a')
      return expand_links.map { |e| ExpandLink.new(e, browser) }
    end
    
    def click
      @browser.execute_script("arguments[0].click();", @elem)
    end
    
    def href
      @href ||= @elem.attribute('href')
    end
    
    def self.top_level_links(links)
      links_at_depths = {}
      links.each do |link|
        if (depth = link.depth)
          links_at_depths[depth] ||= []
          links_at_depths[depth] << link
        end
      end
      return links_at_depths[links_at_depths.keys.min] || []
    end
    
    def depth
      begin
        depth = margin_left[/(\d+)/, 1].to_i / 30
        return depth
      rescue Selenium::WebDriver::Error::StaleElementReferenceError
        # Link is gone
        return nil
      end
    end
    
    def margin_left
      parent = @elem.find_element(xpath: '../../../../../..')
      if parent.attribute('style').present?
        margin_left = parent.style('margin-left')
      else
        margin_left = @elem.find_element(xpath: '../../../../../../..').style('margin-left')
      end
      return margin_left
    end
  end
end