# -*- encoding: utf-8 -*-
GoldRush::Application.routes.draw do

  resources :photos do
    collection do
      get 'list'
      get 'upload'
      get 'get_image'
    end
  end

  resources :tags


  resources :mail_templates


  resources :remarks

  resources :home do
    member do
      put 'change_star'
    end
    collection do
      get 'announcement'
    end
  end

  resources :bp_pic_group_details do
    member do
      put 'suspend'
    end
  end

  resources :bp_pic_groups

  resources :delivery_mails do
    collection do
      get 'contact_mail_new'
      post 'contact_mail_create'
    end
  end

  resources :delivery_mail_targets

  resources :users do
    member do
      put 'fixmessage'
    end
  end

  devise_for :auth, :class_name => User
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'home#index'
 # root :to => 'api#import_mail'
#  root :to => 'application_approval#user_list"'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.

  match ':controller(/:action(/:id))(.:format)'

end
