Rails.application.routes.draw do
  devise_for :users, ActiveAdmin::Devise.config

  ActiveAdmin.routes(self)

  root 'admin/dashboard#index'
end

# == Route Map
#
#               Prefix Verb       URI Pattern                   Controller#Action
#     new_user_session GET        /login(.:format)              active_admin/devise/sessions#new
#         user_session POST       /login(.:format)              active_admin/devise/sessions#create
# destroy_user_session DELETE|GET /logout(.:format)             active_admin/devise/sessions#destroy
#    new_user_password GET        /password/new(.:format)       active_admin/devise/passwords#new
#   edit_user_password GET        /password/edit(.:format)      active_admin/devise/passwords#edit
#        user_password PATCH      /password(.:format)           active_admin/devise/passwords#update
#                      PUT        /password(.:format)           active_admin/devise/passwords#update
#                      POST       /password(.:format)           active_admin/devise/passwords#create
#                 root GET        /                             dashboard#index
#            dashboard GET        /dashboard(.:format)          dashboard#index
#        undelete_user PUT        /users/:id/undelete(.:format) users#undelete
#   batch_action_users POST       /users/batch_action(.:format) users#batch_action
#                users GET        /users(.:format)              users#index
#                      POST       /users(.:format)              users#create
#             new_user GET        /users/new(.:format)          users#new
#            edit_user GET        /users/:id/edit(.:format)     users#edit
#                 user GET        /users/:id(.:format)          users#show
#                      PATCH      /users/:id(.:format)          users#update
#                      PUT        /users/:id(.:format)          users#update
#                      DELETE     /users/:id(.:format)          users#destroy
#             comments GET        /comments(.:format)           comments#index
#                      POST       /comments(.:format)           comments#create
#              comment GET        /comments/:id(.:format)       comments#show
#                      DELETE     /comments/:id(.:format)       comments#destroy
#                      GET        /                             admin/dashboard#index
#
