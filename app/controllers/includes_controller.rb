class IncludesController < ApplicationController
  
  def body
    render plain: params.inspect
  end
end
