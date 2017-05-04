class MoveS3FilePathToWorkflow < ActiveRecord::Migration
  def up
    add_column :workflows, :s3_file_path, :string

    Workflow.reset_column_information

    Workflow.all.each do |workflow|
      if transform = workflow.transforms.file_related.first
        if s3_file_path = transform.read_attribute(:s3_file_path)
          workflow.s3_file_path = s3_file_path
          workflow.save!
        end
      end
    end

    remove_column :transforms, :s3_file_path
  end

  def down
    # I really don't want to deal with making this reversible.
    raise ActiveRecord::IrreversibleMigration
  end
end
