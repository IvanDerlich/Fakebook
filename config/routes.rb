Rails.application.routes.draw do
  authenticated :user do
    root 'posts#index', as: :authenticated_user
  end

  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }, skip: [:sessions]
  
  devise_scope :user do
    get 'sign_in', to: 'devise/sessions#new', as: :new_user_session
    post 'sign_in', to: 'devise/sessions#create', as: :user_session
    delete 'sign_out', to: 'devise/sessions#destroy'
    root 'devise/sessions#new'
  end
  
  get 'dashboard', to: 'users#dashboard'
  get 'notifications', to: 'notifications#show'

  resources :posts do
    resources :comments, skip: [:index, :new]
    resources :likes, only: [:new]
  end
  
  resources :friendships, only: [:new]
  put 'friendships/confirms_friend/:friend_id', to: 'friendships#update', as: :friendship_confirm

  get 'users', to: 'users#index'
  get 'users/:id', to: 'users#show', as: :user
  #resources :users, only: [:show]
  #get 'users/:id', to 'users#'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
