Rails.application.routes.draw do
    root 'users#index'

    namespace :user do
        get '/:username' => '/users#show'
        get '/:username/:post_id' => '/users#post', :post_id => /\d+/
    end
end
