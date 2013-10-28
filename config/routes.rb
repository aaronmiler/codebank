CodeBank::Application.routes.draw do

  root :to => "authorization#index"

  resources :authorization do
    collection do
      get :callback
      get :login
      get :has_repo
      get :need_repo
      post :create_repo
      delete :logout
    end
  end

  resources :main, :path => "/" do
    collection do 
      get :home
      get :about
      get :view
      get :topic
      get :search
      post :save_knowledge
      post :results
      delete :delete
      delete :delete_topic
    end
  end 

  get "/topic/:topic" => "main#topic"
  get "/view/:topic/:file" => "main#view"
  get "/edit/:topic/:file" => "main#edit"
  delete "/delete/:topic/:file" => "main#delete"
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end
  
  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
