class UsersController < ApplicationController
    
    def index
        @users = Dir.glob('public/lj_mirrors/*').select{|e| File.directory?(e) && e.start_with?('.') == false}.map{|e| File.basename(e)}.sort
    end
    
    def show
        username = params[:username]
        redirect_to "/lj_mirrors/#{username}/#{username}.html"
    end
end
