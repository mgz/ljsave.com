class IncludesController < ApplicationController
  
  def body
    render plain: params.inspect
    # @username = params[:uri] ? params[:uri][%r{/lj/(.+?)/}, 1] : 'dummy'
    # @iframe_html = render_to_string(partial: '/includes/body/html', locals: {username: @username}).to_sym.to_s
    #
    # render layout: nil
  end
  
  def head
    @username = params[:uri] ? params[:uri][%r{/lj/(.+?)/}, 1] : 'dummy'
    render layout: nil
  end
end
