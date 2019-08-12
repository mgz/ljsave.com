require "awesome_print"
require 'tty-progressbar'


require_relative 'comment_expander.rb'

class PostDownloader
  attr_reader :url, :title, :time, :comment_count
  
  def initialize(url)
    @url = url
    @id = url[%r{.livejournal.com/(\d+).html}, 1].to_i
    @blog = Blog.new(url[%r{://(.+?).livejournal.com}, 1])
  end
  
  def self.by_blog_and_id(blog, id)
    return PostDownloader.new("https://#{blog.username}.livejournal.com/#{id}.html")
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
    results = Parallel.map(urls, in_processes: 8, progress: "Saving #{urls.size} posts") do |url|
      post = PostDownloader.new(url)
      if File.exists?(post.downloaded_file_path)
        # putsd "Skipping #{post.url}"
        
        post.load_from_cached_file
        
        if post.title && post.time
          # posts << post
          next post
        else
          # Something wrong with it, let's re-download
        end
      end
      
      browser = create_chrome(headless: true, typ: 'desktop')
      
      begin
        post.expand_comments_and_save_page(browser)
        browser.quit
      rescue => e
        puts "#{e.inspect} for #{url}"
        # throw e
      end
      # posts << post
      post
    end
    return results.compact
  end
  
  def expand_comments_and_save_page(browser)
    putsd "Downloading #{@url}"
    browser.navigate.to(@url + '#comments')
    
    if(div = browser.find_elements(class: 'b-msgsystem-warningbox-confirm').first)
      div.find_element(tag_name: 'button').click
    end
    
    if (checkbox = browser.find_elements(id: 'view-own').first) && checkbox.attribute('checked') != 'true'
      putsd 'Setting READABILITY mode'
      browser.execute_script("arguments[0].click();", checkbox)
      sleep 2
      browser.navigate.to(@url + '#comments')
    end
    
    browser.execute_script("document.getElementById('comments').scrollIntoView(true)")
    
    
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
    
    
    if page_count > 1
      
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
  
  def user
    return @user ||= Blog.new(@url[%r{://(.+?)\.}, 1])
  end
  
  def post_id
    return @post_id ||= @url[%r{(\d+)\.html}, 1]
  end
  
  def init_title_and_time(html_doc)
    begin
      @title = html_doc.at_css('h1')&.text&.strip
      
      time_str = html_doc.at_css('time.published').text.strip
      @time = DateTime.strptime(time_str, '%Y-%m-%d %H:%M:%S')
      
      @comment_count = html_doc.css('.b-tree-twig').length
    rescue => e
      puts "Error for #{self.url}:"
      puts e.inspect
      return false
    end
  end
  
  def downloaded_file_path
    return "#{@blog.cached_posts_dir}/#{self.post_id}.html"
  end
  
  def to_json
    return {
      url: @url,
      title: @title,
      time: @time,
      id: post_id,
      comment_count: @comment_count
    }
  end
  
  def mirror
    port = @blog.start_httpd
    @blog.create_mirror_dir
    
    browser = Chrome.create(headless: true, typ: 'desktop')
    load_from_cached_file || expand_comments_and_save_page(browser)
    browser.quit
    
    url = "http://localhost:#{port}/#{@blog.username}/#{File.basename(downloaded_file_path)}"
    putsd url
    `wget -nv --timeout=2 -P #{Blog.out_dir}/#{@blog.username}_files --page-requisites --no-cookies --no-host-directories --span-hosts -E --wait=0 --execute="robots = off"  --convert-links #{url}`
    @blog.stop_httpd
  end
  
  private
  def save_page(contents)
    doc = Nokogiri.HTML(contents) # Parse the document
    doc.css('script').remove # Remove <script>…</script>
    doc.css('noscript').remove
    doc.xpath("//@*[starts-with(name(),'on')]").remove # Remove on____ attributes
    doc.css('header').remove
    doc.css('.b-singlepost-addfriend-link')&.remove
    doc.css('.b-leaf-actions')&.remove
    doc.css("div[suggestion-for-unlogged]")&.remove
    doc.css("div.appwidget")&.remove
    doc.css("div.b-loginform")&.remove
    
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
    # contents.sub!('</head>', '</head><!--#include virtual="/include/head?host=$host&uri=$request_uri" -->')
    # contents.sub!(%r{(<body.+?>)}, '\1<!--#include virtual="/include/body?host=$host&uri=$request_uri" -->')
    
    FileUtils.mkdir_p(@blog.cached_posts_dir)
    File.open(downloaded_file_path, 'w') do |file|
      file << contents
    end
  end
end