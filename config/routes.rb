Rails.application.routes.draw do
  mount ActionCable.server => '/cable'
  
  resource :session
  resources :passwords, param: :token
  resources :registrations, only: [:new, :create]
  resource :settings, only: [:edit, :update]
  resources :posts, only: [:index, :show] do
    member do
      patch :mark_as_read
      patch :mark_as_ignored
      patch :mark_as_responded
    end
  end
  
  resources :sources, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    member do
      post :refresh
      post :test_connection
    end
    
    collection do
      post :refresh_all
    end
  end
  
  get "analysis", to: "analysis#index", as: :analysis

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "posts#index"
end
