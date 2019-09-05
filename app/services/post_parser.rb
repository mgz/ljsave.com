class PostParser
  def initialize(post)
    @post = post
  end
  
  def parsed_html(controller)
    @controller = controller
    @html = File.read("public/lj/#{@post.user.name}/#{@post.user.name}_files/#{@post.user.name}/#{@post.id}.html")
    
    inject_head_content!
    inject_body_content!
    fix_relative_asset_urls!
    # replace_links_to_same_blog!
    replace_links_to_other_downloaded_blogs!
    
    return @html.html_safe
  end
  
  private
  
  def inject_head_content!
    head_content_append = @controller.render_to_string layout: nil, template: 'includes/head', locals: {username: @post.user.name, post_id: @post.id}
    @html.sub!('</head>', "#{head_content_append}</head>")
  end
  
  def inject_body_content!
    body_content_append = @controller.render_to_string layout: nil, template: 'includes/body', locals: {username: @post.user.name, post_id: @post.id}
    @html.sub!(%r{(<body.+?>)}, "\\1#{body_content_append}")
  end
  
  def fix_relative_asset_urls!
    base_path = "/lj/#{@post.user.name}/#{@post.user.name}_files"
    @html.gsub!('href="../', "href=\"#{base_path}/")
    @html.gsub!('src="../', "src=\"#{base_path}/")
  end
  
  def replace_links_to_other_downloaded_blogs!(html: nil, downloaded_user: nil)
    (html || @html).gsub!(%r{"http.?://([^.]+?).livejournal.com(/(\d+).html([^"\s]+?)?)?"}) do |str|
      # puts "str: #{str}"
      username = $1
      post_id = $3
      remaining_part = $4
      
      # puts "username: #{username}, post_id: #{post_id}"
      
      if (user = get_mirrored_user_by_username(username, downloaded_user))
        if post_id.present?
          if remaining_part
            "\"#{user.get_url}/#{post_id}#{remaining_part}\""
          else
            "\"#{user.get_url}/#{post_id}\""
          end
        else
          "\"#{user.get_url}\""
        end
      else
        str
      end
    end
    return html || @html
  end
  
  def get_mirrored_user_by_username(username, downloaded_user)
    if username != 'www' && (user = downloaded_user || User.downloaded_users.find { |u| u.name == username })
      return user
    end
  end
end
