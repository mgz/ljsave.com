require "awesome_print"
require 'tty-progressbar'


require_relative 'comment_expander.rb'

class Post
  attr_reader :url, :title, :time
  
  def initialize(url)
    @url = url
  end
  
  def load_from_cached_file
    if File.exists?(downloaded_file_path)
      html = Nokogiri::HTML(open(downloaded_file_path))
      if init_title_and_time(html)
        return true
      end
    end
    
    return false
  end
  
  def self.save_posts(urls)
    posts = []
    browsers = []
    # Parallel.each(urls, in_processes: 8, progress: "Saving #{urls.size} posts") do |url|
    bar = TTY::ProgressBar.new("Downloading #{urls.size} | ETA: :eta [:bar] :elapsed", total: urls.size)
    urls.each do |url|
      post = Post.new(url)
      
      bar.advance(1)
      
      if File.exists?(post.downloaded_file_path)
        putsd "Skipping #{post.url}"
        
        post.load_from_cached_file
        
        if post.title && post.time
          posts << post
          next
        else
          # Something wrong with it, let's re-download
        end
      end
      
      # browser = browsers[Parallel.worker_number] || create_chrome(headless: true, typ: 'desktop')
      # browsers[Parallel.worker_number] ||= browser
      
      browser = create_chrome(headless: true, typ: 'desktop')
      
      begin
        post.save_page_with_expanded_comments(browser)
        browser.quit
      rescue => e
        puts "#{e.inspect} for #{url}"
        # throw e
      end
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
    
    contents = CommentExpander.expand_all_comments_on_page(browser)
    
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
        putsd "+++ Next page: #{page_num} / #{page_count}"
        browser.navigate.to(@url + "?page=#{page_num}")
        more_content = Nokogiri::HTML(CommentExpander.expand_all_comments_on_page(browser)).at_css('#comments')
        
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
    
    
    doc = Nokogiri.HTML(contents) # Parse the document
    doc.css('script').remove # Remove <script>…</script>
    doc.css('noscript').remove
    doc.xpath("//@*[starts-with(name(),'on')]").remove # Remove on____ attributes
    doc.css('header').remove
    doc.css('.b-singlepost-addfriend-link')&.remove
    doc.css('.b-leaf-actions')&.remove
    doc.css("div[suggestion-for-unlogged]")&.remove
    doc.css("div.appwidget")&.remove
    
    doc.css("link[rel=home]")&.remove
    doc.css("link[rel=contents]")&.remove
    doc.css("link[rel=help]")&.remove
    doc.css("link[rel=canonical]")&.remove
    doc.css("link[rel=preload]")&.remove
    doc.css("link[rel=prefetch]")&.remove
    doc.css("link[rel=next]")&.remove
    
    doc.css("meta[property]")&.remove
    
    # TODO: clean invisible iframes (<iframe frameborder="0" src="../index.html%3F%3Fplain%252FcrossStorageServ.html%3F&amp;v=1563267629.html" style="display: none; width: 0px; height: 0px; border: 0px;"></iframe><div class="ng-scope" lj-messages-init="true">)
    
    # Expand spoilers
    doc.css('.lj-spoiler').add_class('lj-spoiler-opened')
    
    contents = doc.to_html
    
    # Inject my content
    contents.sub!('</head>', '</head><!--#include virtual="/include/head?host=$host&uri=$request_uri" -->')
    contents.sub!(%r{(<body.+?>)}, '\1<!--#include virtual="/include/body?host=$host&uri=$request_uri" -->')
    
    FileUtils.mkdir_p(user.cached_posts_dir)
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
      return false
    end
  end
  
  def downloaded_file_path
    return "#{user.cached_posts_dir}/#{self.post_id}.html"
  end
end