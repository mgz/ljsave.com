class User < ApplicationRecord
    
    def self.get_root_url(username, request:)
        # if Rails.env.production?
        #     return "//#{username}.#{request.host_with_port}"
        # else
            return "//#{request.host_with_port}/user/#{username}"
        # end
    end
end
