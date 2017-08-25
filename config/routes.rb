# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: 'users/registrations' }
  ActiveAdmin.routes(self)
  root to: 'home#index'
  get 'home/about'

  get 'profile' => 'users#show'
  patch 'profile' => 'users#update'

  resources :home, only: %i[] do
    collection do
      get :about
      get :contact
    end
  end

  resources :diagnoses, only: %i[index destroy] do
    get 'step-1' => 'diagnoses#step1', on: :collection

    member do
      get 'step-2' => 'diagnoses#step2'
      get 'step-3' => 'diagnoses#step3'
      get 'step-4' => 'diagnoses#step4'
      get 'step-5' => 'diagnoses#step5'
      post :notify_experts
    end
  end

  resources :visits, only: %i[show] do
    resources :diagnoses, only: %i[show]
  end

  resources :companies, only: %i[show], param: :siret do
    collection do
      post :search_by_siren
      post :search_by_name
      post :create_diagnosis_from_siret
    end
  end

  resources :mailto_logs, only: %i[create]

  namespace :api do
    resources :facilities, only: %i[] do
      post :search_by_siret, on: :collection
    end

    resources :diagnoses, only: %i[show create update] do
      resources :diagnosed_needs, only: %i[create] do
        post :bulk, on: :collection
      end
    end

    resources :visits, only: %i[update] do
      resources :contacts, only: %i[index create]
    end

    resources :contacts, only: %i[show update destroy] do
      get :contact_button_expert, on: :collection
    end
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
