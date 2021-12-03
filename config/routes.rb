Rails.application.routes.draw do
  devise_for :users, ActiveAdmin::Devise.config

  ActiveAdmin.routes(self)

  require 'sidekiq/web'
  authenticate :user do
    mount Sidekiq::Web => '/sidekiq'
  end

  root 'admin/dashboard#index'
end

# == Route Map
#
#                                     Prefix Verb       URI Pattern                                                                              Controller#Action
#                           new_user_session GET        /login(.:format)                                                                         active_admin/devise/sessions#new
#                               user_session POST       /login(.:format)                                                                         active_admin/devise/sessions#create
#                       destroy_user_session DELETE|GET /logout(.:format)                                                                        active_admin/devise/sessions#destroy
#                          new_user_password GET        /password/new(.:format)                                                                  active_admin/devise/passwords#new
#                         edit_user_password GET        /password/edit(.:format)                                                                 active_admin/devise/passwords#edit
#                              user_password PATCH      /password(.:format)                                                                      active_admin/devise/passwords#update
#                                            PUT        /password(.:format)                                                                      active_admin/devise/passwords#update
#                                            POST       /password(.:format)                                                                      active_admin/devise/passwords#create
#                                       root GET        /                                                                                        workflows#index
#                                  customers GET        /customers(.:format)                                                                     customers#index
#                                            POST       /customers(.:format)                                                                     customers#create
#                               new_customer GET        /customers/new(.:format)                                                                 customers#new
#                              edit_customer GET        /customers/:id/edit(.:format)                                                            customers#edit
#                                   customer GET        /customers/:id(.:format)                                                                 customers#show
#                                            PATCH      /customers/:id(.:format)                                                                 customers#update
#                                            PUT        /customers/:id(.:format)                                                                 customers#update
#                                            DELETE     /customers/:id(.:format)                                                                 customers#destroy
#          batch_action_data_quality_reports POST       /data_quality_reports/batch_action(.:format)                                             data_quality_reports#batch_action
#                       data_quality_reports GET        /data_quality_reports(.:format)                                                          data_quality_reports#index
#                                            POST       /data_quality_reports(.:format)                                                          data_quality_reports#create
#                    new_data_quality_report GET        /data_quality_reports/new(.:format)                                                      data_quality_reports#new
#                   edit_data_quality_report GET        /data_quality_reports/:id/edit(.:format)                                                 data_quality_reports#edit
#                        data_quality_report GET        /data_quality_reports/:id(.:format)                                                      data_quality_reports#show
#                                            PATCH      /data_quality_reports/:id(.:format)                                                      data_quality_reports#update
#                                            PUT        /data_quality_reports/:id(.:format)                                                      data_quality_reports#update
#                                            DELETE     /data_quality_reports/:id(.:format)                                                      data_quality_reports#destroy
#                 batch_action_notifications POST       /notifications/batch_action(.:format)                                                    notifications#batch_action
#                               notification DELETE     /notifications/:id(.:format)                                                             notifications#destroy
#                         make_immutable_run PUT        /runs/:id/make_immutable(.:format)                                                       runs#make_immutable
#                           make_mutable_run PUT        /runs/:id/make_mutable(.:format)                                                         runs#make_mutable
#                            dump_schema_run PUT        /runs/:id/dump_schema(.:format)                                                          runs#dump_schema
#                    dump_execution_plan_run PUT        /runs/:id/dump_execution_plan(.:format)                                                  runs#dump_execution_plan
#                          batch_action_runs POST       /runs/batch_action(.:format)                                                             runs#batch_action
#                                       runs GET        /runs(.:format)                                                                          runs#index
#                                        run GET        /runs/:id(.:format)                                                                      runs#show
#                                            DELETE     /runs/:id(.:format)                                                                      runs#destroy
#                 batch_action_run_step_logs POST       /run_step_logs/batch_action(.:format)                                                    run_step_logs#batch_action
#                               run_step_log GET        /run_step_logs/:id(.:format)                                                             run_step_logs#show
#                  batch_action_sql_snippets POST       /sql_snippets/batch_action(.:format)                                                     sql_snippets#batch_action
#                               sql_snippets GET        /sql_snippets(.:format)                                                                  sql_snippets#index
#                                            POST       /sql_snippets(.:format)                                                                  sql_snippets#create
#                            new_sql_snippet GET        /sql_snippets/new(.:format)                                                              sql_snippets#new
#                           edit_sql_snippet GET        /sql_snippets/:id/edit(.:format)                                                         sql_snippets#edit
#                                sql_snippet GET        /sql_snippets/:id(.:format)                                                              sql_snippets#show
#                                            PATCH      /sql_snippets/:id(.:format)                                                              sql_snippets#update
#                                            PUT        /sql_snippets/:id(.:format)                                                              sql_snippets#update
#                                            DELETE     /sql_snippets/:id(.:format)                                                              sql_snippets#destroy
#                    batch_action_transforms POST       /transforms/batch_action(.:format)                                                       transforms#batch_action
#                                 transforms GET        /transforms(.:format)                                                                    transforms#index
#                                            POST       /transforms(.:format)                                                                    transforms#create
#                              new_transform GET        /transforms/new(.:format)                                                                transforms#new
#                             edit_transform GET        /transforms/:id/edit(.:format)                                                           transforms#edit
#                                  transform GET        /transforms/:id(.:format)                                                                transforms#show
#                                            PATCH      /transforms/:id(.:format)                                                                transforms#update
#                                            PUT        /transforms/:id(.:format)                                                                transforms#update
#                                            DELETE     /transforms/:id(.:format)                                                                transforms#destroy
#        batch_action_transform_dependencies POST       /transform_dependencies/batch_action(.:format)                                           transform_dependencies#batch_action
#                       transform_dependency DELETE     /transform_dependencies/:id(.:format)                                                    transform_dependencies#destroy
#         batch_action_transform_validations POST       /transform_validations/batch_action(.:format)                                            transform_validations#batch_action
#                      transform_validations POST       /transform_validations(.:format)                                                         transform_validations#create
#                   new_transform_validation GET        /transform_validations/new(.:format)                                                     transform_validations#new
#                  edit_transform_validation GET        /transform_validations/:id/edit(.:format)                                                transform_validations#edit
#                       transform_validation GET        /transform_validations/:id(.:format)                                                     transform_validations#show
#                                            PATCH      /transform_validations/:id(.:format)                                                     transform_validations#update
#                                            PUT        /transform_validations/:id(.:format)                                                     transform_validations#update
#                                            DELETE     /transform_validations/:id(.:format)                                                     transform_validations#destroy
#                              undelete_user PUT        /users/:id/undelete(.:format)                                                            users#undelete
#                         batch_action_users POST       /users/batch_action(.:format)                                                            users#batch_action
#                                      users GET        /users(.:format)                                                                         users#index
#                                            POST       /users(.:format)                                                                         users#create
#                                   new_user GET        /users/new(.:format)                                                                     users#new
#                                  edit_user GET        /users/:id/edit(.:format)                                                                users#edit
#                                       user GET        /users/:id(.:format)                                                                     users#show
#                                            PATCH      /users/:id(.:format)                                                                     users#update
#                                            PUT        /users/:id(.:format)                                                                     users#update
#                                            DELETE     /users/:id(.:format)                                                                     users#destroy
#                   batch_action_validations POST       /validations/batch_action(.:format)                                                      validations#batch_action
#                                validations GET        /validations(.:format)                                                                   validations#index
#                                            POST       /validations(.:format)                                                                   validations#create
#                             new_validation GET        /validations/new(.:format)                                                               validations#new
#                            edit_validation GET        /validations/:id/edit(.:format)                                                          validations#edit
#                                 validation GET        /validations/:id(.:format)                                                               validations#show
#                                            PATCH      /validations/:id(.:format)                                                               validations#update
#                                            PUT        /validations/:id(.:format)                                                               validations#update
#                                            DELETE     /validations/:id(.:format)                                                               validations#destroy
#                 revert_paper_trail_version PUT        /paper_trail_versions/:id/revert(.:format)                                               paper_trail_versions#revert
#          batch_action_paper_trail_versions POST       /paper_trail_versions/batch_action(.:format)                                             paper_trail_versions#batch_action
#                        paper_trail_version GET        /paper_trail_versions/:id(.:format)                                                      paper_trail_versions#show
#                     batch_action_workflows POST       /workflows/batch_action(.:format)                                                        workflows#batch_action
#                                  workflows GET        /workflows(.:format)                                                                     workflows#index
#                                            POST       /workflows(.:format)                                                                     workflows#create
#                               new_workflow GET        /workflows/new(.:format)                                                                 workflows#new
#                              edit_workflow GET        /workflows/:id/edit(.:format)                                                            workflows#edit
#                                   workflow GET        /workflows/:id(.:format)                                                                 workflows#show
#                                            PATCH      /workflows/:id(.:format)                                                                 workflows#update
#                                            PUT        /workflows/:id(.:format)                                                                 workflows#update
#                                            DELETE     /workflows/:id(.:format)                                                                 workflows#destroy
#                 run_workflow_configuration PUT        /workflow_configurations/:id/run(.:format)                                               workflow_configurations#run
#       batch_action_workflow_configurations POST       /workflow_configurations/batch_action(.:format)                                          workflow_configurations#batch_action
#                    workflow_configurations GET        /workflow_configurations(.:format)                                                       workflow_configurations#index
#                                            POST       /workflow_configurations(.:format)                                                       workflow_configurations#create
#                 new_workflow_configuration GET        /workflow_configurations/new(.:format)                                                   workflow_configurations#new
#                edit_workflow_configuration GET        /workflow_configurations/:id/edit(.:format)                                              workflow_configurations#edit
#                     workflow_configuration GET        /workflow_configurations/:id(.:format)                                                   workflow_configurations#show
#                                            PATCH      /workflow_configurations/:id(.:format)                                                   workflow_configurations#update
#                                            PUT        /workflow_configurations/:id(.:format)                                                   workflow_configurations#update
#                                            DELETE     /workflow_configurations/:id(.:format)                                                   workflow_configurations#destroy
# batch_action_workflow_data_quality_reports POST       /workflow_data_quality_reports/batch_action(.:format)                                    workflow_data_quality_reports#batch_action
#              workflow_data_quality_reports POST       /workflow_data_quality_reports(.:format)                                                 workflow_data_quality_reports#create
#           new_workflow_data_quality_report GET        /workflow_data_quality_reports/new(.:format)                                             workflow_data_quality_reports#new
#          edit_workflow_data_quality_report GET        /workflow_data_quality_reports/:id/edit(.:format)                                        workflow_data_quality_reports#edit
#               workflow_data_quality_report GET        /workflow_data_quality_reports/:id(.:format)                                             workflow_data_quality_reports#show
#                                            PATCH      /workflow_data_quality_reports/:id(.:format)                                             workflow_data_quality_reports#update
#                                            PUT        /workflow_data_quality_reports/:id(.:format)                                             workflow_data_quality_reports#update
#                                            DELETE     /workflow_data_quality_reports/:id(.:format)                                             workflow_data_quality_reports#destroy
#                                   comments GET        /comments(.:format)                                                                      comments#index
#                                            POST       /comments(.:format)                                                                      comments#create
#                                    comment GET        /comments/:id(.:format)                                                                  comments#show
#                                            DELETE     /comments/:id(.:format)                                                                  comments#destroy
#                                sidekiq_web            /sidekiq                                                                                 Sidekiq::Web
#                                            GET        /                                                                                        admin/dashboard#index
#                         rails_service_blob GET        /rails/active_storage/blobs/:signed_id/*filename(.:format)                               active_storage/blobs#show
#                  rails_blob_representation GET        /rails/active_storage/representations/:signed_blob_id/:variation_key/*filename(.:format) active_storage/representations#show
#                         rails_disk_service GET        /rails/active_storage/disk/:encoded_key/*filename(.:format)                              active_storage/disk#show
#                  update_rails_disk_service PUT        /rails/active_storage/disk/:encoded_token(.:format)                                      active_storage/disk#update
#                       rails_direct_uploads POST       /rails/active_storage/direct_uploads(.:format)                                           active_storage/direct_uploads#create
