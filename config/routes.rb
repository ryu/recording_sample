Rails.application.routes.draw do
  resources :recordings
  root "recordings#index"
end
