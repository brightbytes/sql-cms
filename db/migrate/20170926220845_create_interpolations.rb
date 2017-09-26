class CreateInterpolations < ActiveRecord::Migration[5.1]
  def change
    create_table :interpolations do |t|
      t.with_options(null: false) do |tt|
        tt.string :name
        tt.string :slug
        tt.string :sql
      end
    end

    execute "CREATE UNIQUE INDEX index_interpolations_on_lowercase_slug ON interpolations USING btree (lower(slug))"
    execute "CREATE UNIQUE INDEX index_interpolations_on_lowercase_name ON interpolations USING btree (lower(name))"

  end
end
