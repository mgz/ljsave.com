class IncludesController < ApplicationController
  
  def body
    @username = params[:uri] ? params[:uri][%r{/lj/(.+?)/}, 1] : 'dummy'
    @iframe_html = render_to_string(partial: '/includes/body/html', locals: {username: @username}).to_sym.to_s
  end
end
