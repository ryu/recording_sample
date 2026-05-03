Rails.application.routes.draw do
  resources :recordings do
    patch :restore, on: :member
  end
  root "recordings#index"
end
