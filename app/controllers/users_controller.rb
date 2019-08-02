class UsersController < ApplicationController
    caches_action :show, expires_in: 5.minutes
    
    def index
        @page_title = "Сохраненные копии ЖЖ-дневников, с комментариями"
        @users = Dir.glob('public/lj/*').select{|e| File.directory?(e) && e.start_with?('.') == false}.map{|e| File.basename(e)}.sort
    end
    
    def show
        @username = params[:username]
        json = JSON.parse(File.read("public/lj/#{@username}/#{@username}.json"))
        @years = json['years']
        
        @navbar_text = "Копия ЖЖ #{@username}.livejournal.com"
        
        @page_title = "Копия ЖЖ #{@username} с развернутыми комментариями"
        
        # html = File.read("public/lj/#{@username}/#{@username}.html")
        # liker = render_to_string partial: 'users/show/like', locals: {username: @username}
        # html.sub! '<div id="content">', %{#{liker}<div id="content">}
        # render html: html.html_safe
    end
    
    def post
        username = params[:username]
        post_id = params[:post_id].to_i
        
        html = File.read("public/lj/#{username}/#{username}_files/#{username}/#{post_id}.html").html_safe
        
        head_content_append = render_to_string layout: nil, template: 'includes/head'

        body_content_append = render_to_string layout: nil, template: 'includes/body', locals: {username: username, post_id: post_id}
        
        html.sub!('</head>', "</head>#{head_content_append}")
        html.sub!(%r{(<body.+?>)}, "\\1#{body_content_append}")
        
        render html: html.html_safe, layout: nil
    end
    
    def post_nav
        @username = params[:username]
        @post_id = params[:post_id].to_i
        
        render layout: nil
    end
end
