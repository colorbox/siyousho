Rails.application.routes.draw do
  root "home#index"
  get "/about", to: "home#about"
  get "sign_up", to: "users#new"
  post "users", to: "users#create"
  get "user_dashboard", to: "users#dashboard"
end