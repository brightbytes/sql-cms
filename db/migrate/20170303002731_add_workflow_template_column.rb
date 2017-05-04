class AddWorkflowTemplateColumn < ActiveRecord::Migration[4.2]
  def change
    add_column :workflows, :template, :boolean, null: false, default: false
  end
end
