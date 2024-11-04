require 'sidekiq/web'

Rails.application.routes.draw do
  resources :comments
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "home#index"

  resources :articles do
    resources :comments, only: [:create, :destroy]
    post "delete_barons_comments", on: :member
  end

  mount Sidekiq::Web => "/sidekiq" # mount Sidekiq::Web in your Rails app
end
