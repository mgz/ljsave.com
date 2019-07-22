class IncludesController < ApplicationController
  
  def body
    render plain: ERB::Util.h(params.inspect)
  end
end
