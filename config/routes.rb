Rails.application.routes.draw do
    root 'users#index'

    namespace :user do
        get ':username' => '/users#show'
    end
end
