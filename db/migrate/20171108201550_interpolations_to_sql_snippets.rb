class InterpolationsToSqlSnippets < ActiveRecord::Migration[5.1]
  def change
    rename_table :interpolations, :sql_snippets
  end
end
