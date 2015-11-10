Rails.application.routes.draw do
  root 'static_pages#home'
  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }
  resources :authorisations, only: [:index, :show, :create, :update]
  get 'authorisation/requesting', to: 'authorisations#requesting', as: 'authorisation_request'
  get 'authorisation/grant', to: 'authorisations#granting'
  resources :threads, only: [:show]
  post 'threads/update_tags'
  resources :attachment, only: [:show] do
  	get :download_inline, on: :collection
  end
end
