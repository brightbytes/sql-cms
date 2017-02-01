Rails.application.routes.draw do
  devise_for :users, ActiveAdmin::Devise.config

  ActiveAdmin.routes(self)

  root 'admin/dashboard#index'
end

# == Route Map
#
#                              Prefix Verb       URI Pattern                                    Controller#Action
#                    new_user_session GET        /login(.:format)                               active_admin/devise/sessions#new
#                        user_session POST       /login(.:format)                               active_admin/devise/sessions#create
#                destroy_user_session DELETE|GET /logout(.:format)                              active_admin/devise/sessions#destroy
#                   new_user_password GET        /password/new(.:format)                        active_admin/devise/passwords#new
#                  edit_user_password GET        /password/edit(.:format)                       active_admin/devise/passwords#edit
#                       user_password PATCH      /password(.:format)                            active_admin/devise/passwords#update
#                                     PUT        /password(.:format)                            active_admin/devise/passwords#update
#                                     POST       /password(.:format)                            active_admin/devise/passwords#create
#                                root GET        /                                              dashboard#index
#                   undelete_customer PUT        /customers/:id/undelete(.:format)              customers#undelete
#              batch_action_customers POST       /customers/batch_action(.:format)              customers#batch_action
#                           customers GET        /customers(.:format)                           customers#index
#                                     POST       /customers(.:format)                           customers#create
#                        new_customer GET        /customers/new(.:format)                       customers#new
#                       edit_customer GET        /customers/:id/edit(.:format)                  customers#edit
#                            customer GET        /customers/:id(.:format)                       customers#show
#                                     PATCH      /customers/:id(.:format)                       customers#update
#                                     PUT        /customers/:id(.:format)                       customers#update
#                                     DELETE     /customers/:id(.:format)                       customers#destroy
#                           dashboard GET        /dashboard(.:format)                           dashboard#index
#                  undelete_data_file PUT        /data_files/:id/undelete(.:format)             data_files#undelete
#             batch_action_data_files POST       /data_files/batch_action(.:format)             data_files#batch_action
#                          data_files GET        /data_files(.:format)                          data_files#index
#                                     POST       /data_files(.:format)                          data_files#create
#                       new_data_file GET        /data_files/new(.:format)                      data_files#new
#                      edit_data_file GET        /data_files/:id/edit(.:format)                 data_files#edit
#                           data_file GET        /data_files/:id(.:format)                      data_files#show
#                                     PATCH      /data_files/:id(.:format)                      data_files#update
#                                     PUT        /data_files/:id(.:format)                      data_files#update
#                                     DELETE     /data_files/:id(.:format)                      data_files#destroy
#          batch_action_notifications POST       /notifications/batch_action(.:format)          notifications#batch_action
#                        notification DELETE     /notifications/:id(.:format)                   notifications#destroy
#             batch_action_transforms POST       /transforms/batch_action(.:format)             transforms#batch_action
#                          transforms GET        /transforms(.:format)                          transforms#index
#                                     POST       /transforms(.:format)                          transforms#create
#                       new_transform GET        /transforms/new(.:format)                      transforms#new
#                      edit_transform GET        /transforms/:id/edit(.:format)                 transforms#edit
#                           transform GET        /transforms/:id(.:format)                      transforms#show
#                                     PATCH      /transforms/:id(.:format)                      transforms#update
#                                     PUT        /transforms/:id(.:format)                      transforms#update
#                                     DELETE     /transforms/:id(.:format)                      transforms#destroy
# batch_action_transform_dependencies POST       /transform_dependencies/batch_action(.:format) transform_dependencies#batch_action
#                transform_dependency DELETE     /transform_dependencies/:id(.:format)          transform_dependencies#destroy
#  batch_action_transform_validations POST       /transform_validations/batch_action(.:format)  transform_validations#batch_action
#               transform_validations POST       /transform_validations(.:format)               transform_validations#create
#            new_transform_validation GET        /transform_validations/new(.:format)           transform_validations#new
#                transform_validation DELETE     /transform_validations/:id(.:format)           transform_validations#destroy
#                       undelete_user PUT        /users/:id/undelete(.:format)                  users#undelete
#                  batch_action_users POST       /users/batch_action(.:format)                  users#batch_action
#                               users GET        /users(.:format)                               users#index
#                                     POST       /users(.:format)                               users#create
#                            new_user GET        /users/new(.:format)                           users#new
#                           edit_user GET        /users/:id/edit(.:format)                      users#edit
#                                user GET        /users/:id(.:format)                           users#show
#                                     PATCH      /users/:id(.:format)                           users#update
#                                     PUT        /users/:id(.:format)                           users#update
#                                     DELETE     /users/:id(.:format)                           users#destroy
#            batch_action_validations POST       /validations/batch_action(.:format)            validations#batch_action
#                         validations GET        /validations(.:format)                         validations#index
#                                     POST       /validations(.:format)                         validations#create
#                      new_validation GET        /validations/new(.:format)                     validations#new
#                     edit_validation GET        /validations/:id/edit(.:format)                validations#edit
#                          validation GET        /validations/:id(.:format)                     validations#show
#                                     PATCH      /validations/:id(.:format)                     validations#update
#                                     PUT        /validations/:id(.:format)                     validations#update
#                                     DELETE     /validations/:id(.:format)                     validations#destroy
#              batch_action_workflows POST       /workflows/batch_action(.:format)              workflows#batch_action
#                           workflows GET        /workflows(.:format)                           workflows#index
#                                     POST       /workflows(.:format)                           workflows#create
#                        new_workflow GET        /workflows/new(.:format)                       workflows#new
#                       edit_workflow GET        /workflows/:id/edit(.:format)                  workflows#edit
#                            workflow GET        /workflows/:id(.:format)                       workflows#show
#                                     PATCH      /workflows/:id(.:format)                       workflows#update
#                                     PUT        /workflows/:id(.:format)                       workflows#update
#                                     DELETE     /workflows/:id(.:format)                       workflows#destroy
#                            comments GET        /comments(.:format)                            comments#index
#                                     POST       /comments(.:format)                            comments#create
#                             comment GET        /comments/:id(.:format)                        comments#show
#                                     DELETE     /comments/:id(.:format)                        comments#destroy
#                                     GET        /                                              admin/dashboard#index
#
