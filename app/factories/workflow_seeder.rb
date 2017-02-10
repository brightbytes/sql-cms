module WorkflowSeeder

  extend self

  def seed
    CustomerSeeder.seed
    [
      Workflow.where(name: 'Public Data Workflow, version 1').first_or_create!(customer: Customer.where(name: CustomerSeeder::CUSTOMERS[1]).first),
      Workflow.where(name: 'SIS Data Workflow, version 1').first_or_create!(customer: Customer.where(name: CustomerSeeder::CUSTOMERS[0]).first),
      create_demo_workflow!
    ].each { |workflow| notify_me!(workflow) }
  end

  private

  def notify_me!(workflow)
    workflow.notifications.first_or_create!(user: User.where(email: 'aaron@brightbytes.net').first)
  end

  def demo_customer
    @demo_customer ||= Customer.where(name: CustomerSeeder::CUSTOMERS[2]).first
  end

  def demo_workflow
    @demo_workflow ||= Workflow.where(name: 'Demo Workflow, version 1').first_or_create!(customer: demo_customer)
  end

  def create_demo_workflow!
    staging_boces_mappings_table_transform = create_demo_transform!(
      name: "CREATE TABLE staging_boces_mappings",
      runner: 'RailsMigration',
      sql: <<-SQL.strip_heredoc
        create_table :staging_boces_mappings do |t|
          t.integer :clarity_org_id, index: true
          t.integer :co_org_id, index: true
        end
      SQL
    )

    staging_district_mappings_table_transform = create_demo_transform!(
      name: "CREATE TABLE staging_district_mappings",
      runner: 'RailsMigration',
      sql: <<-SQL.strip_heredoc
        create_table :staging_district_mappings do |t|
          t.integer :clarity_org_id, index: true
          t.integer :co_org_id, index: true
        end
      SQL
    )

    staging_school_mappings_table_transform = create_demo_transform!(
      name: "CREATE TABLE staging_school_mappings",
      runner: 'RailsMigration',
      sql: <<-SQL.strip_heredoc
        create_table :staging_school_mappings do |t|
          t.integer :clarity_org_id, index: true
          t.integer :co_org_id, index: true
          t.string :added_on_date_s
        end
      SQL
    )

    staging_fund_mappings_table_transform = create_demo_transform!(
      name: "CREATE TABLE staging_fund_mappings",
      runner: 'RailsMigration',
      sql: <<-SQL.strip_heredoc
        create_table :staging_fund_mappings do |t|
          t.string :fund_name
          t.integer :fund_low_val
          t.integer :fund_high_val
        end
      SQL
    )

    staging_facts_table_transform = create_demo_transform!(
      name: "CREATE TABLE staging_facts",
      runner: 'RailsMigration',
      sql: <<-SQL.strip_heredoc
        create_table :staging_facts do |t|
          t.integer :boces_id, index: true
          t.integer :admin_unit
          t.integer :school_code, index: true
          t.integer :fund_code, index: true
          t.integer :location_code
          t.integer :sre_code
          t.integer :program_code, index: true
          t.integer :object_source_code, index: true
          t.integer :job_class_code
          t.integer :grant_code
          t.integer :amount_cents
        end
      SQL
    )

    school_mappings_table_transform = create_demo_transform!(
      name: "CREATE TABLE school_mappings",
      runner: 'RailsMigration',
      sql: <<-SQL.strip_heredoc
        create_table :school_mappings do |t|
          t.integer :staging_school_mapping_id, null: false
          t.integer :clarity_org_id, index: true
          t.integer :co_org_id, index: true
          t.date :added_on
        end
        add_index :school_mappings, :staging_school_mapping_id, unique: true
        add_foreign_key :school_mappings, :staging_school_mappings
      SQL
    )

    create_demo_dependency!(prerequisite_transform: staging_school_mappings_table_transform, postrequisite_transform: school_mappings_table_transform)

    school_parent_mappings_table_transform = create_demo_transform!(
      name: "CREATE TABLE school_parent_mappings",
      runner: 'RailsMigration',
      sql: <<-SQL.strip_heredoc
        create_table :school_parent_mappings do |t|
          t.integer :staging_school_parent_mapping_id, null: false
          t.string :staging_school_parent_mapping_type
          t.integer :clarity_org_id, index: true
          t.integer :co_org_id, index: true
        end
        add_index :school_parent_mappings, [:staging_school_parent_mapping_id, :staging_school_parent_mapping_type], unique: true, name: :index_school_parent_mappings_on_unique_parent_mapping_id_type
      SQL
    )

    mapped_facts_table_transform = create_demo_transform!(
      name: "CREATE TABLE mapped_facts",
      runner: 'RailsMigration',
      sql: <<-SQL.strip_heredoc
        create_table :mapped_facts do |t|
          t.integer :staging_fact_id, null: false
          t.integer :clarity_school_parent_id, index: true
          t.integer :clarity_school_org_id, index: true
          t.string :fund_type, index: true
        end
        add_index :mapped_facts, :staging_fact_id, unique: true
        add_foreign_key :mapped_facts, :staging_facts
      SQL
    )

    create_demo_dependency!(prerequisite_transform: staging_facts_table_transform, postrequisite_transform: mapped_facts_table_transform)

    reduced_facts_table_transform = create_demo_transform!(
      name: "CREATE TABLE reduced_facts",
      runner: 'RailsMigration',
      sql: <<-SQL.strip_heredoc
        create_table :reduced_facts do |t|
          t.integer :clarity_school_parent_id, index: true
          t.integer :clarity_school_org_id, index: true
          t.string :fund_type, index: true
          t.integer :program_code, index: true
          t.integer :object_source_code, index: true
          t.integer :total_amount_cents
        end
      SQL
    )

    staging_boces_mappings_data_file = create_demo_data_file!(
      name: "BOCES mappings",
      s3_file_name: 'boces_mappings.csv'
    )

    staging_boces_mappings_loader_transform = create_demo_transform!(
      name: "BOCES staging dimension table loader",
      runner: "CopyFrom",
      sql: "COPY staging_boces_mappings (clarity_org_id, co_org_id) FROM STDIN WITH CSV HEADER",
      data_file: staging_boces_mappings_data_file
    )

    create_demo_dependency!(prerequisite_transform: staging_boces_mappings_table_transform, postrequisite_transform: staging_boces_mappings_loader_transform)

    create_demo_transform_validation!(
      transform: staging_boces_mappings_loader_transform,
      validation: Validation.non_null,
      params: { table_name: :staging_boces_mappings, column_name: :clarity_org_id }
    )

    create_demo_transform_validation!(
      transform: staging_boces_mappings_loader_transform,
      validation: Validation.non_null,
      params: { table_name: :staging_boces_mappings, column_name: :co_org_id }
    )

    create_demo_transform_validation!(
      transform: staging_boces_mappings_loader_transform,
      validation: Validation.uniqueness,
      params: { table_name: :staging_boces_mappings, column_name: :co_org_id }
    )

    staging_district_mappings_data_file = create_demo_data_file!(
      name: "District mappings",
      s3_file_name: 'district_mappings.csv'
    )

    staging_district_mappings_loader_transform = create_demo_transform!(
      name: "District staging dimension table loader",
      runner: "CopyFrom",
      sql: "COPY staging_district_mappings (clarity_org_id, co_org_id) FROM STDIN WITH CSV HEADER",
      data_file: staging_district_mappings_data_file
    )

    create_demo_dependency!(prerequisite_transform: staging_district_mappings_table_transform, postrequisite_transform: staging_district_mappings_loader_transform)

    create_demo_transform_validation!(
      transform: staging_district_mappings_loader_transform,
      validation: Validation.non_null,
      params: { table_name: :staging_district_mappings, column_name: :clarity_org_id }
    )

    create_demo_transform_validation!(
      transform: staging_district_mappings_loader_transform,
      validation: Validation.non_null,
      params: { table_name: :staging_district_mappings, column_name: :co_org_id }
    )

    create_demo_transform_validation!(
      transform: staging_district_mappings_loader_transform,
      validation: Validation.uniqueness,
      params: { table_name: :staging_district_mappings, column_name: :co_org_id }
    )

    staging_school_mappings_data_file = create_demo_data_file!(
      name: "School mappings",
      s3_file_name: 'school_mappings.csv'
    )

    staging_school_mappings_loader_transform = create_demo_transform!(
      name: "School staging dimension table loader",
      runner: "CopyFrom",
      sql: "COPY staging_school_mappings (clarity_org_id, co_org_id, added_on_date_s) FROM STDIN WITH CSV HEADER",
      data_file: staging_school_mappings_data_file
    )

    create_demo_dependency!(prerequisite_transform: staging_school_mappings_table_transform, postrequisite_transform: staging_school_mappings_loader_transform)

    create_demo_transform_validation!(
      transform: staging_school_mappings_loader_transform,
      validation: Validation.non_null,
      params: { table_name: :staging_school_mappings, column_name: :clarity_org_id }
    )

    create_demo_transform_validation!(
      transform: staging_school_mappings_loader_transform,
      validation: Validation.non_null,
      params: { table_name: :staging_school_mappings, column_name: :co_org_id }
    )

    create_demo_transform_validation!(
      transform: staging_school_mappings_loader_transform,
      validation: Validation.uniqueness,
      params: { table_name: :staging_school_mappings, column_name: :co_org_id }
    )

    staging_fund_mappings_data_file = create_demo_data_file!(
      name: "Fund mappings",
      s3_file_name: 'fund_mappings.csv'
    )

    staging_fund_mappings_loader_transform = create_demo_transform!(
      name: "Fund staging dimension table loader",
      runner: "CopyFrom",
      sql: "COPY staging_fund_mappings (fund_name, fund_low_val, fund_high_val) FROM STDIN WITH CSV HEADER",
      data_file: staging_fund_mappings_data_file
    )

    create_demo_dependency!(prerequisite_transform: staging_fund_mappings_table_transform, postrequisite_transform: staging_fund_mappings_loader_transform)

    create_demo_transform_validation!(
      transform: staging_fund_mappings_loader_transform,
      validation: Validation.presence,
      params: { table_name: :staging_fund_mappings, column_name: :fund_name },
    )

    create_demo_transform_validation!(
      transform: staging_fund_mappings_loader_transform,
      validation: Validation.non_null,
      params: { table_name: :staging_fund_mappings, column_name: :fund_low_val }
    )

    create_demo_transform_validation!(
      transform: staging_fund_mappings_loader_transform,
      validation: Validation.uniqueness,
      params: { table_name: :staging_fund_mappings, column_name: :fund_high_val }
    )

    create_demo_transform_validation!(
      transform: staging_fund_mappings_loader_transform,
      validation: Validation.non_overlapping,
      params: { table_name: :staging_fund_mappings, low_column_name: :fund_low_val, high_column_name: :fund_high_val }
    )

    boces_9035_data_file = create_demo_data_file!(
      name: "BOCES 9035 data",
      s3_file_name: 'boces_9035_sample.csv'
    )

    staging_facts_loader_transform = create_demo_transform!(
      name: "BOCES 9035 fact table loader",
      runner: "CopyFrom",
      sql: "COPY staging_facts (boces_id, admin_unit, school_code, fund_code, location_code, sre_code, program_code, object_source_code, job_class_code, grant_code, amount_cents) FROM STDIN WITH CSV HEADER",
      data_file: boces_9035_data_file
    )

    create_demo_dependency!(prerequisite_transform: staging_facts_table_transform, postrequisite_transform: staging_facts_loader_transform)

    [
      { params: { table_name: :staging_facts, column_name: :boces_id } },
      { params: { table_name: :staging_facts, column_name: :school_code } },
      { params: { table_name: :staging_facts, column_name: :fund_code } },
      { params: { table_name: :staging_facts, column_name: :program_code } },
      { params: { table_name: :staging_facts, column_name: :object_source_code } },
      { params: { table_name: :staging_facts, column_name: :amount_cents } }
    ].each { |h| create_demo_transform_validation!(h.merge(transform: staging_facts_loader_transform, validation: Validation.non_null)) }


    

    demo_workflow.reload
  end

  def create_demo_transform!(**options)
    Transform.where(name: options.delete(:name)).first_or_create!(options.merge(workflow: demo_workflow))
  end

  def create_demo_dependency!(**options)
    TransformDependency.where(options).first_or_create!
  end

  def create_demo_data_file!(**options)
    DataFile.where(name: options.delete(:name)).first_or_create!(options.merge(s3_bucket_name: :bb_dpl_cms, customer: demo_customer))
  end

  def create_demo_transform_validation!(**options)
    TransformValidation.where(transform: options.delete(:transform), validation: options.delete(:validation)).first_or_create!(options)
  end

end
