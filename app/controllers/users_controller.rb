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
        render html: File.read("public/lj/#{username}/#{username}_files/#{username}/#{params[:post_id]}.html").html_safe
    end
end
