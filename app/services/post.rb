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
    replace_links_to_same_blog!
    
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
  
  def replace_links_to_same_blog!
    @html.gsub!(%r{"http.?://#{@user.name}.livejournal.com/((\d+).html)?}) do |str|
      puts str
      puts '$1', $1
      puts '$2', $2
      if $2.present?
        "\"#{@user.get_url}/#{$2}"
      else
        str
      end
    end
  end
end
