class AddWorkflowTemplateColumn < ActiveRecord::Migration[5.0]
  def change
    add_column :workflows, :template, :boolean, null: false, default: false
  end
end
