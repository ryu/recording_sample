Rails.application.routes.draw do
  resources :recordings, only: [:index, :new, :create, :show, :edit, :update, :destroy]
  root "recordings#index"
end
