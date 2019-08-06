class UsersController < ApplicationController
  caches_action :show, expires_in: 5.minutes
  caches_action :post, expires_in: 1.hours
  
  def index
    @page_title = "Сохраненные копии ЖЖ-дневников, с комментариями"
    @users = Dir.glob('public/lj/*').select { |e| File.directory?(e) && e.start_with?('.') == false }.map { |e| File.basename(e) }.sort
    @users.map!{|u| User.new(u)}
  end
  
  def show
    @user = User.new(params[:username])
    json = @user.posts_hash
    @years = json['years']
    
    @navbar_text = "Копия ЖЖ #{@user.name}.livejournal.com"
    
    @page_title = "Копия ЖЖ #{@user.name} с развернутыми комментариями"
  end
  
  def post
    username = params[:username]
    post_id = params[:post_id].to_i
    
    post = Post.new(id: post_id, username: username)
    
    render html: post.parsed_html(self), layout: nil
  end
  
  def post_nav
    @username = params[:username]
    @post_id = params[:post_id].to_i
    
    render layout: nil
  end
  
  def search
    @q = params[:text]
    @page_title = @q
  end
end
