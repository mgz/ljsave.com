class UsersController < ApplicationController
    
    def index
        @users = Dir.glob('public/lj/*').select{|e| File.directory?(e) && e.start_with?('.') == false}.map{|e| File.basename(e)}.sort
    end
    
    def show
        username = params[:username]
        render html: File.read("public/lj/#{username}/#{username}.html").html_safe
    end
    
    def post
        username = params[:username]
        render html: File.read("public/lj/#{username}/#{username}_files/#{username}/#{params[:post_id]}.html").html_safe
    end
end
