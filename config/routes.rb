Rails.application.routes.draw do
  devise_for :users, ActiveAdmin::Devise.config

  ActiveAdmin.routes(self)

  root 'admin/dashboard#index'
end

# == Route Map
#
#                     Prefix Verb       URI Pattern                           Controller#Action
#           new_user_session GET        /login(.:format)                      active_admin/devise/sessions#new
#               user_session POST       /login(.:format)                      active_admin/devise/sessions#create
#       destroy_user_session DELETE|GET /logout(.:format)                     active_admin/devise/sessions#destroy
#          new_user_password GET        /password/new(.:format)               active_admin/devise/passwords#new
#         edit_user_password GET        /password/edit(.:format)              active_admin/devise/passwords#edit
#              user_password PATCH      /password(.:format)                   active_admin/devise/passwords#update
#                            PUT        /password(.:format)                   active_admin/devise/passwords#update
#                            POST       /password(.:format)                   active_admin/devise/passwords#create
#                       root GET        /                                     dashboard#index
#          undelete_customer PUT        /customers/:id/undelete(.:format)     customers#undelete
#     batch_action_customers POST       /customers/batch_action(.:format)     customers#batch_action
#                  customers GET        /customers(.:format)                  customers#index
#                            POST       /customers(.:format)                  customers#create
#               new_customer GET        /customers/new(.:format)              customers#new
#              edit_customer GET        /customers/:id/edit(.:format)         customers#edit
#                   customer GET        /customers/:id(.:format)              customers#show
#                            PATCH      /customers/:id(.:format)              customers#update
#                            PUT        /customers/:id(.:format)              customers#update
#                            DELETE     /customers/:id(.:format)              customers#destroy
#                  dashboard GET        /dashboard(.:format)                  dashboard#index
#         undelete_data_file PUT        /data_files/:id/undelete(.:format)    data_files#undelete
#    batch_action_data_files POST       /data_files/batch_action(.:format)    data_files#batch_action
#                 data_files GET        /data_files(.:format)                 data_files#index
#                            POST       /data_files(.:format)                 data_files#create
#              new_data_file GET        /data_files/new(.:format)             data_files#new
#             edit_data_file GET        /data_files/:id/edit(.:format)        data_files#edit
#                  data_file GET        /data_files/:id(.:format)             data_files#show
#                            PATCH      /data_files/:id(.:format)             data_files#update
#                            PUT        /data_files/:id(.:format)             data_files#update
#                            DELETE     /data_files/:id(.:format)             data_files#destroy
# batch_action_notifications POST       /notifications/batch_action(.:format) notifications#batch_action
#              notifications POST       /notifications(.:format)              notifications#create
#           new_notification GET        /notifications/new(.:format)          notifications#new
#               notification DELETE     /notifications/:id(.:format)          notifications#destroy
#              undelete_user PUT        /users/:id/undelete(.:format)         users#undelete
#         batch_action_users POST       /users/batch_action(.:format)         users#batch_action
#                      users GET        /users(.:format)                      users#index
#                            POST       /users(.:format)                      users#create
#                   new_user GET        /users/new(.:format)                  users#new
#                  edit_user GET        /users/:id/edit(.:format)             users#edit
#                       user GET        /users/:id(.:format)                  users#show
#                            PATCH      /users/:id(.:format)                  users#update
#                            PUT        /users/:id(.:format)                  users#update
#                            DELETE     /users/:id(.:format)                  users#destroy
#     batch_action_workflows POST       /workflows/batch_action(.:format)     workflows#batch_action
#                  workflows GET        /workflows(.:format)                  workflows#index
#                            POST       /workflows(.:format)                  workflows#create
#               new_workflow GET        /workflows/new(.:format)              workflows#new
#              edit_workflow GET        /workflows/:id/edit(.:format)         workflows#edit
#                   workflow GET        /workflows/:id(.:format)              workflows#show
#                            PATCH      /workflows/:id(.:format)              workflows#update
#                            PUT        /workflows/:id(.:format)              workflows#update
#                            DELETE     /workflows/:id(.:format)              workflows#destroy
#                   comments GET        /comments(.:format)                   comments#index
#                            POST       /comments(.:format)                   comments#create
#                    comment GET        /comments/:id(.:format)               comments#show
#                            DELETE     /comments/:id(.:format)               comments#destroy
#                            GET        /                                     admin/dashboard#index
#
