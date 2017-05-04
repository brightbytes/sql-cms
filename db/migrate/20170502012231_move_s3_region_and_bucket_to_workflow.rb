class MoveS3RegionAndBucketToWorkflow < ActiveRecord::Migration[4.2]
  def up
    add_column :workflows, :s3_region_name, :string
    add_column :workflows, :s3_bucket_name, :string

    Workflow.reset_column_information

    Workflow.all.each do |workflow|
      if transform = workflow.transforms.file_related.first
        s3_region_name = transform.read_attribute(:s3_region_name)
        s3_bucket_name = transform.read_attribute(:s3_bucket_name)
      end
      workflow.s3_region_name = s3_region_name || ENV.fetch('DEFAULT_S3_REGION', 'us-west-2')
      workflow.s3_bucket_name = s3_bucket_name || ENV['DEFAULT_S3_BUCKET']
      workflow.save!
    end

    change_column_null :workflows, :s3_region_name, false
    change_column_null :workflows, :s3_bucket_name, false

    remove_column :transforms, :s3_region_name
    remove_column :transforms, :s3_bucket_name
  end

  def down
    # I really don't want to deal with making this reversible.
    raise ActiveRecord::IrreversibleMigration
  end
end
