Rails.application.routes.draw do
  resources :recordings, except: %i[ new create ] do
    resource :restoration, only: :create
  end

  resources :documents, only: %i[ new create ]
  resources :articles, only: %i[ new create ]

  root "recordings#index"
end
