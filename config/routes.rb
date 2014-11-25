# -*- encoding: utf-8 -*-
GoldRush::Application.routes.draw do

  resources :help do
    collection do
      get 'privacy'
      get 'terms'
    end
  end

  resources :special_words

  namespace :import_mail_match do
    match '/show/:id' => :show
  end

  get 'import_mail_match/change_status/:id' => 'import_mail_match#change_status', as: 'imm_change_status'


  resources :photos do
    collection do
      get 'list'
      get 'upload'
      get 'rotate'
      get 'get_image'
    end
  end

  resources :tags do
    collection do
      post "fix"
    end
  end

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
    member do
      put 'add_matching'
    end
    collection do
      put 'fix_matching'
      put 'unlink_matching'
      get 'contact_mail_new'
      post 'contact_mail_create'
      get 'reply_mail_new'
      post 'reply_mail_create'
    end
  end

  resources :delivery_mail_targets

  resources :users do
    member do
      put 'fixmessage'
    end
  end

  resources :daily_report do
    collection do
      get 'list'
      get 'summary'
    end
  end

  devise_for :auth, :class_name => User, :controllers => {
    :sessions => 'auth/sessions',
    :registrations => 'auth/registrations',
    :confirmations => 'auth/confirmations'
  }

  devise_scope :auth do
    get 'auth/edit_smtp_setting' => 'auth/registrations#edit_smtp_setting'
    get 'auth/show_smtp_setting' => 'auth/registrations#show_smtp_setting'
    put 'auth/update_smtp_setting' => 'auth/registrations#update_smtp_setting'
  end

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
