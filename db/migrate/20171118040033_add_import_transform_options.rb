class AddImportTransformOptions < ActiveRecord::Migration[5.1]
  def change
    add_column :workflow_configurations, :import_transform_options, :text
  end
end
