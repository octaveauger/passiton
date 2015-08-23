Rails.application.routes.draw do
  root 'static_pages#home'
  get 'timeline', to: 'static_pages#timeline'
  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }
  resources :authorisations, only: [:index, :show, :create, :update]
  get 'authorisations/requesting/:granter_id', to: 'authorisations#requesting', as: 'authorisation_request'
  get 'authorisation/grant', to: 'authorisations#granting'
end
