Rails.application.routes.draw do
    root 'users#index'

    namespace :user do
        get 'user/:username' => '/users#show'
    end
end
