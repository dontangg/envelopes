Envelopes::Application.routes.draw do

  # Default actions for resources:
  #   index, new, create, show, edit, update, destroy

  resources :rules, only: [:index, :create, :update, :destroy]

  resources :envelopes, except: [:new, :edit] do
    collection do
      get 'fill'
      post 'fill' => 'envelopes#perform_fill', as: :perform_fill
      get 'manage'
    end
  end

  resources :transactions, only: [:update] do
    collection do
      put 'update_all'
      post 'create_transfer'
      get 'suggest_payee'
      post 'import'
    end
  end

  resources :users, only: [:edit, :update]

  get 'login' => 'sessions#new'
  post 'login' => 'sessions#create'
  get 'logout' => 'sessions#destroy'

  root to: 'envelopes#index'

end
