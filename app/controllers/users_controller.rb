class UsersController < ApplicationController
  caches_action :show, expires_in: 5.minutes
  caches_action :year, expires_in: 5.minutes
  caches_action :post, expires_in: 1.hours
  
  def index
    @page_title = "Сохраненные копии ЖЖ-дневников, с комментариями"
    @users = User.downloaded_users.sort_by(&:name)
  end
  
  def show
    @user = User.new(params[:username])
    
    posts_hash = @user.posts_hash
    @years = posts_hash['years']
    
    @too_many_posts = posts_hash['posts'].size > 5000
    
    @navbar_text = "Копия ЖЖ #{@user.name}.livejournal.com"
    
    @page_title = "Копия ЖЖ #{@user.name} с развернутыми комментариями"
  end
  
  def year
    @user = User.new(params[:username])
    @year = params[:year]
    
    @posts = @user.posts_hash['years'][@year]
        
    @navbar_text = "Копия ЖЖ #{@user.name}.livejournal.com (#{@year})"

    @page_title = "Копия ЖЖ #{@user.name} с развернутыми комментариями за #{@year} г."
  end
  
  def post
    username = params[:username]
    post_id = params[:post_id].to_i
    
    post = Post.new(id: post_id, username: username)
    render html: PostParser.new(post).parsed_html(self), layout: nil
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
