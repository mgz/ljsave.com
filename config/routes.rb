Rails.application.routes.draw do
  root 'users#index'
  
  namespace :user do
    get '/:username' => '/users#show'
    get '/:username/:post_id/nav' => '/users#post_nav', :post_id => /\d+/
    get '/:username/year/:year' => '/users#year'
    get '/:username/:post_id' => '/users#post', :post_id => /\d+/
  end
  
  get '/include/head' => 'includes#head'
  get '/include/body' => 'includes#body'
  
  get '/search' => 'users#search'
  


end
