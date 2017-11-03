class AddWorkflowDefaultParams < ActiveRecord::Migration[5.1]
  def change
    add_column :workflows, :params, :jsonb
  end
end
