require "awesome_print"
require 'tty-progressbar'

module Downloader
  class RemotePost
    attr_reader :url, :title, :time, :comment_count, :blog

    def initialize(url, blog: nil)
      @url = url
      @id = url[%r{.livejournal.com/(\d+).html}, 1].to_i
      @blog = blog || RemoteBlog.new(url[%r{://(.+?).livejournal.com}, 1])
      load_from_cache
    end

    def self.by_blog_and_id(blog, id)
      return RemotePost.new("https://#{blog.username}.livejournal.com/#{id}.html")
    end

    def self.save_posts_to_cache(urls)
      results = Parallel.map(urls, in_processes: 8, progress: "Saving #{urls.size} posts") do |url|
        post = RemotePost.new(url)
        if File.exists?(post.cached_file_path)
          # putsd "Skipping #{post.url}"

          post.load_from_cache

          if post.title && post.time
            # posts << post
            next post
          else
            # Something wrong with it, let's re-download
          end
        end

        begin
          post.download_expand_comments_and_save_cache
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

    def cached?
      return File.exists?(cached_file_path)
    end

    def user
      return @user ||= RemoteBlog.new(@url[%r{://(.+?)\.}, 1])
    end

    def post_id
      return @post_id ||= @url[%r{(\d+)\.html}, 1]
    end

    def init_title_and_time
      unless @html_doc
        download_expand_comments_and_save_cache
      end

      begin
        @title = @html_doc.at_css('h1')&.text&.strip || 'NO TITLE'

        time_str = @html_doc.at_css('time.published').text.strip
        @time = DateTime.strptime(time_str, '%Y-%m-%d %H:%M:%S')

        init_comment_count
      rescue => e
        # raise e
        puts "Error for #{self.url}:"
        puts e.inspect
        delete_cached_html
        return false
      end
    end

    def cached_file_path
      return "#{@blog.cached_posts_dir}/#{self.post_id}.html"
    end

    def delete_cached_html
      File.delete cached_file_path if File.exists? cached_file_path
    end

    def to_s
      return "https://#{@blog.username}.livejournal.com/#{@id}.html"
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
      @blog.create_mirror_dir

      download_expand_comments_and_save_cache

      url = "http://localhost:#{@blog.httpd_port}/#{@blog.username}/#{File.basename(cached_file_path)}"
      putsd url
      `wget -q -nv --timeout=2 -P #{@blog.out_dir}/#{@blog.username}_files --page-requisites --no-cookies --no-host-directories --span-hosts -E --wait=0 --execute="robots = off"  --convert-links #{url}`
    end

    private

    def expand_next_comment_pages
      if @page_count > 1
        comments_html = @html_doc.at_css('#comments')
        (2..@page_count).each do |page_num|
          putsd "+++ Next page: #{page_num} / #{@page_count}"
          @browser.navigate.to(@url + "?page=#{page_num}")
          more_content = Nokogiri::HTML(CommentExpander.new(@browser).expand_all_comments_on_page).at_css('#comments')

          # Remove pager
          more_content.css('.b-xylem')&.remove


          comments_html.add_child(more_content.inner_html)
        end
      end
    end

    def expand_first_page_of_comments
      contents = CommentExpander.new(@browser).expand_all_comments_on_page

      @page_count = determine_page_count
      putsd "Post has #{@page_count} pages"

      @html_doc = Nokogiri::HTML(contents)

      init_title_and_time

      @html_doc.css('.b-pager')&.remove
      @html_doc.css('.b-xylem')[1]&.remove
      @html_doc.css('.b-xylem-cell')&.remove
      @html_doc.css('.b-singlepost-standout')&.remove
      @html_doc.css('footer')&.remove
      @html_doc.css('.b-discoverytimes-wrapper')&.remove
      @html_doc.css('.ljsale')&.remove
      @html_doc.css('.lj-recommended')&.remove
    end

    def determine_page_count
      @browser.find_elements(class: 'b-pager-page').last&.text&.to_i || 1
    end

    def scroll_to_comments
      @browser.execute_script("if(document.getElementById('comments')){document.getElementById('comments').scrollIntoView(true)}")
    end

    def prepare_browser(retry_no = 0)
      @browser ||= Chrome.create(headless: true, typ: 'desktop')
      @browser.navigate.to(@url + '#comments')
      if @browser.page_source.include? 'This site can’t be reached'
        raise ProxyError if retry_no > 5
        return prepare_browser(retry_no + 1)
      end
      return @browser
    end

    def with_browser
      prepare_browser
      yield
      @browser.quit
    end

    def click_readability_checkbox
      if (checkbox = @browser.find_elements(id: 'view-own').first) && checkbox.attribute('checked') != 'true'
        putsd 'Setting READABILITY mode'
        @browser.execute_script("arguments[0].click();", checkbox)
        sleep 2
        @browser.navigate.to(@url + '#comments')
      end
    end

    def accept_18_years_warning
      if (div = @browser.find_elements(class: 'b-msgsystem-warningbox-confirm').first)
        div.find_element(tag_name: 'button').click
      end
    end

    def save_page
      remove_unneeded_elements
      expand_spoilers

      FileUtils.mkdir_p(@blog.cached_posts_dir)
      File.open(cached_file_path, 'w') do |file|
        file << @html_doc.to_html
      end
    end

    def remove_unneeded_elements
      @html_doc.css("div[prev-next-nav]")&.remove
      @html_doc.css('.b-leaf-footer')&.remove
      @html_doc.css('script').remove # Remove <script>…</script>
      @html_doc.css('noscript').remove
      @html_doc.xpath("//@*[starts-with(name(),'on')]").remove # Remove on____ attributes
      @html_doc.css('header').remove
      @html_doc.css('.b-singlepost-addfriend-link')&.remove
      @html_doc.css('.b-leaf-actions')&.remove
      @html_doc.css("div[suggestion-for-unlogged]")&.remove
      @html_doc.css("div.appwidget")&.remove
      @html_doc.css("div.b-loginform")&.remove

      @html_doc.css("link[rel=home]")&.remove
      @html_doc.css("link[rel=contents]")&.remove
      @html_doc.css("link[rel=help]")&.remove
      @html_doc.css("link[rel=canonical]")&.remove
      @html_doc.css("link[rel=preload]")&.remove
      @html_doc.css("link[rel=prefetch]")&.remove
      @html_doc.css("link[rel=next]")&.remove

      @html_doc.css("meta[property]")&.remove

      # TODO: clean invisible iframes (<iframe frameborder="0" src="../index.html%3F%3Fplain%252FcrossStorageServ.html%3F&amp;v=1563267629.html" style="display: none; width: 0px; height: 0px; border: 0px;"></iframe><div class="ng-scope" lj-messages-init="true">)
    end

    def expand_spoilers
      @html_doc.css('.lj-spoiler').add_class('lj-spoiler-opened')
    end

    def download_expand_comments_and_save_cache
      putsd "Downloading #{@url}"
      with_browser do
        accept_18_years_warning
        click_readability_checkbox
        scroll_to_comments
        expand_first_page_of_comments
        expand_next_comment_pages
        init_comment_count
      end
      save_page
    end

    def init_comment_count
      @comment_count = @html_doc.css('.b-tree-twig').length
    end

    def load_from_cache
      if cached?
        @html_doc = Nokogiri::HTML(open(cached_file_path))
        if init_title_and_time
          return true
        end
      end
      return false
    end
  end
end
