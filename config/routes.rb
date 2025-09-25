Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs/v1'
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API Routes
  namespace :api do
    namespace :v1 do
      get 'dashboard', to: 'dashboard#index'
      resources :projects
      resources :tasks
      resources :focus_sessions do
        collection do
          get :current
          get :stats
        end
        member do
          patch :stop
        end
      end
      resources :tags do
        collection do
          get :popular
          get :stats
          get :for_task
          post :assign_to_task
          delete :remove_from_task
        end
      end
    end
  end

  # Defines the root path route ("/")
  root "dashboard#index"
end
