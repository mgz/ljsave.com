class Post
  def initialize(id:, username:)
    @id = id
    @user = User.new(username)
  end
  
  def parsed_html(controller)
    @controller = controller
    @html = File.read("public/lj/#{@user.name}/#{@user.name}_files/#{@user.name}/#{@id}.html")
    
    inject_head_content!
    inject_body_content!
    fix_relative_asset_urls!
    # replace_links_to_same_blog!
    replace_links_to_other_downloaded_blogs!
    
    return @html.html_safe
  end
  
  private
  
  def inject_head_content!
    head_content_append = @controller.render_to_string layout: nil, template: 'includes/head', locals: {username: @user.name, post_id: @id}
    @html.sub!('</head>', "#{head_content_append}</head>")
  end
  
  def inject_body_content!
    body_content_append = @controller.render_to_string layout: nil, template: 'includes/body', locals: {username: @user.name, post_id: @id}
    @html.sub!(%r{(<body.+?>)}, "\\1#{body_content_append}")
  end
  
  def fix_relative_asset_urls!
    base_path = "/lj/#{@user.name}/#{@user.name}_files"
    @html.gsub!('href="../', "href=\"#{base_path}/")
    @html.gsub!('src="../', "src=\"#{base_path}/")
  end
  
  # def replace_links_to_same_blog!
  #   @html.gsub!(%r{"http.?://([^.]+?).livejournal.com/((\d)+.html([^"\s]+?)?)?"}) do |str|
  #     if $2.present?
  #       "\"#{@user.get_url}/#{$2}"
  #     else
  #       str
  #     end
  #   end
  # end
  
  def replace_links_to_other_downloaded_blogs!(html: nil, downloaded_user: nil)
    (html || @html).gsub!(%r{"http.?://([^.]+?).livejournal.com/((\d+).html([^"\s]+?)?)?"}) do |str|
      # puts "str: #{str}"
      username = $1
      post_id = $3
      
      # puts "username: #{username}, post_id: #{post_id}"
      
      if username != 'www' && (user = downloaded_user || User.downloaded_users.find { |u| u.name == username })
        if post_id.present?
          "\"#{user.get_url}/#{post_id}\""
        else
          "\"#{user.get_url}\""
        end
      else
        str
      end
    end
    return html || @html
  end
end
