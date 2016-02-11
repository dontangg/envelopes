Envelopes::Application.routes.draw do

  # Default actions for resources:
  #   index, new, create, show, edit, update, destroy

  resources :transfer_rules, only: [:index, :create, :update, :destroy]

  resources :rules, only: [:index, :create, :update, :destroy] do
    collection do
      post 'run_all'
    end
  end

  resources :envelopes, except: [:new, :edit] do
    collection do
      get 'fill'
      post 'fill' => 'envelopes#perform_fill', as: :perform_fill
      get 'manage'
    end
    resources :transactions, only: [:index]
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

  get 'sign_in' => 'sessions#new'
  post 'sign_in' => 'sessions#create'
  get 'sign_out' => 'sessions#destroy'

  root to: 'envelopes#index'

end
