class AddWorkflowTemplateColumn < ActiveRecord::Migration
  def change
    add_column :workflows, :template, :boolean, null: false, default: false
  end
end
