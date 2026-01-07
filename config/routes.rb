Rails.application.routes.draw do
  resources :recordings do
    post :restore, on: :member
  end
  root "recordings#index"
end
