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

  def demo_workflow
    @demo_workflow ||= Workflow.where(name: 'Demo Workflow, version 1').first_or_create!(customer: demo_customer)
  end

  private

  def notify_me!(workflow)
    workflow.notifications.first_or_create!(user: User.where(email: 'aaron@brightbytes.net').first)
  end

  def demo_customer
    @demo_customer ||= Customer.where(name: CustomerSeeder::CUSTOMERS[2]).first
  end

  def create_demo_workflow!

    # DDL Transforms

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
          t.integer :co_school_id, index: true
          t.date :added_on
        end
        add_index :school_mappings, :staging_school_mapping_id, unique: true
        add_foreign_key :school_mappings, :staging_school_mappings
      SQL
    )

    # Because of the foreign key
    create_demo_dependency!(prerequisite_transform: staging_school_mappings_table_transform, postrequisite_transform: school_mappings_table_transform)

    school_parent_mappings_table_transform = create_demo_transform!(
      name: "CREATE TABLE school_parent_mappings",
      runner: 'RailsMigration',
      sql: <<-SQL.strip_heredoc
        create_table :school_parent_mappings do |t|
          t.integer :staging_school_parent_mapping_id, null: false
          t.string :staging_school_parent_mapping_type
          t.integer :clarity_org_id, index: true
          t.integer :co_school_parent_id, index: true
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
          t.integer :clarity_school_parent_org_id, index: true
          t.integer :clarity_school_org_id, index: true
          t.string :fund_type, index: true
        end
        add_index :mapped_facts, :staging_fact_id, unique: true
        add_foreign_key :mapped_facts, :staging_facts
      SQL
    )

    # Because of the foreign key
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

    # CopyFrom Transforms

    staging_boces_mappings_data_file = create_demo_data_file!(
      name: "BOCES mappings",
      s3_file_path: 'fake_customer/demo_workflow_version_1/source_data_files',
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
      s3_file_path: 'fake_customer/demo_workflow_version_1/source_data_files',
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
      s3_file_path: 'fake_customer/demo_workflow_version_1/source_data_files',
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
      s3_file_path: 'fake_customer/demo_workflow_version_1/source_data_files',
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
      s3_file_path: 'fake_customer/demo_workflow_version_1/source_data_files',
      s3_file_name: 'boces_9035_sample.csv'
    )

    staging_facts_loader_transform = create_demo_transform!(
      name: "BOCES 9035 fact table loader",
      runner: "CopyFrom",
      sql: "COPY staging_facts (boces_id, admin_unit, school_code, fund_code, location_code, sre_code, program_code, object_source_code, job_class_code, grant_code, amount_cents) FROM STDIN WITH CSV HEADER",
      data_file: boces_9035_data_file
    )

    create_demo_dependency!(prerequisite_transform: staging_facts_table_transform, postrequisite_transform: staging_facts_loader_transform)

    # Note that we only perform validation of columns we'll need further along in the flow.

    [
      { params: { table_name: :staging_facts, column_name: :boces_id } },
      { params: { table_name: :staging_facts, column_name: :school_code } },
      { params: { table_name: :staging_facts, column_name: :fund_code } },
      { params: { table_name: :staging_facts, column_name: :program_code } },
      { params: { table_name: :staging_facts, column_name: :object_source_code } },
      { params: { table_name: :staging_facts, column_name: :amount_cents } }
    ].each { |h| create_demo_transform_validation!(h.merge(transform: staging_facts_loader_transform, validation: Validation.non_null)) }

    # DataQualityReports for CopyFrom Transforms

    create_data_quality_report!(
      name: "Staging BOCES Mappings table count",
      sql: "SELECT count(1) FROM staging_boces_mappings"
    )

    create_data_quality_report!(
      name: "Staging District Mappings table count",
      sql: "SELECT count(1) FROM staging_district_mappings"
    )

    create_data_quality_report!(
      name: "Staging School Mappings table count",
      sql: "SELECT count(1) FROM staging_school_mappings"
    )

    create_data_quality_report!(
      name: "Staging Fund Mappings table count",
      sql: "SELECT count(1) FROM staging_fund_mappings"
    )

    create_data_quality_report!(
      name: "Staging Fact Mappings table count",
      sql: "SELECT count(1) FROM staging_facts"
    )

    # Dimension Initial Mapping Transforms

    school_mappings_initial_map_transform = create_demo_transform!(
      name: "School org mapped dimension table initial-loader",
      sql: <<-SQL.strip_heredoc
        INSERT INTO school_mappings (staging_school_mapping_id, clarity_org_id, co_school_id)
        SELECT id, clarity_org_id, co_org_id FROM staging_school_mappings
      SQL
    )

    create_demo_dependency!(prerequisite_transform: school_mappings_table_transform, postrequisite_transform: school_mappings_initial_map_transform)
    create_demo_dependency!(prerequisite_transform: staging_school_mappings_loader_transform, postrequisite_transform: school_mappings_initial_map_transform)

    # Note that we don't bother with validations of the staging_school_mapping_id column because its NOT NULL, UNIQUE and FK constraints are all in the DB.

    create_demo_transform_validation!(
      transform: school_mappings_initial_map_transform,
      validation: Validation.non_null,
      params: { table_name: :school_mappings, column_name: :clarity_org_id }
    )

    create_demo_transform_validation!(
      transform: school_mappings_initial_map_transform,
      validation: Validation.non_null,
      params: { table_name: :school_mappings, column_name: :co_school_id }
    )

    create_demo_transform_validation!(
      transform: school_mappings_initial_map_transform,
      validation: Validation.uniqueness,
      params: { table_name: :school_mappings, column_name: :co_school_id }
    )

    school_parent_mappings_initial_map_transform = create_demo_transform!(
      name: "School Parent org mapped dimension table initial-loader",
      sql: <<-SQL.strip_heredoc
        INSERT INTO school_parent_mappings (staging_school_parent_mapping_id, staging_school_parent_mapping_type, clarity_org_id, co_school_parent_id)
        SELECT id, 'District', clarity_org_id, co_org_id FROM staging_district_mappings UNION SELECT id, 'BOCES', clarity_org_id, co_org_id FROM staging_boces_mappings
      SQL
    )

    create_demo_dependency!(prerequisite_transform: school_parent_mappings_table_transform, postrequisite_transform: school_parent_mappings_initial_map_transform)
    create_demo_dependency!(prerequisite_transform: staging_district_mappings_loader_transform, postrequisite_transform: school_parent_mappings_initial_map_transform)
    create_demo_dependency!(prerequisite_transform: staging_boces_mappings_loader_transform, postrequisite_transform: school_parent_mappings_initial_map_transform)

    # Note that we don't bother with validations of the staging_school_parent_mapping_id column because its NOT NULL, UNIQUE and FK constraints are all in the DB.

    create_demo_transform_validation!(
      transform: school_parent_mappings_initial_map_transform,
      validation: Validation.non_null,
      params: { table_name: :school_parent_mappings, column_name: :clarity_org_id }
    )

    create_demo_transform_validation!(
      transform: school_parent_mappings_initial_map_transform,
      validation: Validation.non_null,
      params: { table_name: :school_parent_mappings, column_name: :co_school_parent_id }
    )

    create_demo_transform_validation!(
      transform: school_parent_mappings_initial_map_transform,
      validation: Validation.uniqueness,
      params: { table_name: :school_parent_mappings, column_name: :co_school_parent_id }
    )

    # Fact Initial Mapping Transform

    # Note that for Mapped Fact tables, we don't copy-forward identity-mapped columns, since they will be accessible by FK, and Fact tables can be **HUGE**
    # (Whereas, by contrast, we **do** copy-forward identity-mapped columns for Dimensions, since Dimension tables are small.)
    fact_initial_map_transform  = create_demo_transform!(
      name: "Mapped fact table initial-loader",
      sql: "INSERT INTO mapped_facts (staging_fact_id) SELECT id FROM staging_facts"
    )

    create_demo_dependency!(prerequisite_transform: mapped_facts_table_transform, postrequisite_transform: fact_initial_map_transform)
    create_demo_dependency!(prerequisite_transform: staging_facts_loader_transform, postrequisite_transform: fact_initial_map_transform)

    # Note that we don't bother with validations of the staging_fact_id column because its NOT NULL, UNIQUE and FK constraints are all in the DB.

    # Mapping Transforms

    school_mappings_map_transform = create_demo_transform!(
      name: "School org mapped dimension table added_on column-loader",
      sql: <<-SQL.strip_heredoc
        UPDATE school_mappings AS sm
           SET added_on = TO_DATE(ssm.added_on_date_s, 'YYYY.MM.DD')
          FROM staging_school_mappings ssm
         WHERE sm.staging_school_mapping_id = ssm.id
      SQL
    )

    # We have no validation of ^^ because we don't give a shit.  ^^ exists as an example of a "data format-conversion" Map Transform only.

    create_demo_dependency!(prerequisite_transform: school_mappings_initial_map_transform, postrequisite_transform: school_mappings_map_transform)

    # Note that the next 3 Map Transforms are more complex than the previous transform because we're not carrying the fund_code and CO Org IDs forward
    #  to the mapped fact table

    fact_fund_type_map_transform = create_demo_transform!(
      name: "Mapped fact table fund_type column-loader",
      sql: <<-SQL.strip_heredoc
        UPDATE mapped_facts AS mf
           SET fund_type = sfm.fund_name
          FROM staging_facts sf, staging_fund_mappings sfm
         WHERE mf.staging_fact_id = sf.id
           AND sf.fund_code BETWEEN sfm.fund_low_val AND sfm.fund_high_val
      SQL
    )

    create_demo_dependency!(prerequisite_transform: fact_initial_map_transform, postrequisite_transform: fact_fund_type_map_transform)

    create_demo_transform_validation!(
      transform: fact_fund_type_map_transform,
      validation: Validation.presence,
      params: { table_name: :mapped_facts, column_name: :fund_type }
    )

    # This is borderline-unnecessary, but again is again mainly here as an example of some of the more-obvious validations
    create_demo_transform_validation!(
      transform: fact_fund_type_map_transform,
      validation: Validation.fk,
      params: { table_name: :mapped_facts, fk_table_name: :mapped_facts, fk_column_name: :fund_type, pk_table_name: :staging_fund_mappings, pk_column_name: :fund_name }
    )

    fact_parent_org_map_transform = create_demo_transform!(
      name: "Mapped fact table clarity_school_parent_org_id column-loader",
      sql: <<-SQL.strip_heredoc
        UPDATE mapped_facts AS mf
           SET clarity_school_parent_org_id = spm.clarity_org_id
          FROM staging_facts sf, school_parent_mappings spm
         WHERE mf.staging_fact_id = sf.id
           AND sf.boces_id = spm.co_school_parent_id
      SQL
    )

    create_demo_dependency!(prerequisite_transform: fact_initial_map_transform, postrequisite_transform: fact_parent_org_map_transform)
    create_demo_dependency!(prerequisite_transform: school_parent_mappings_initial_map_transform, postrequisite_transform: fact_parent_org_map_transform)


    create_demo_transform_validation!(
      transform: fact_parent_org_map_transform,
      validation: Validation.non_null,
      params: { table_name: :mapped_facts, column_name: :clarity_school_parent_org_id }
    )

    # This is borderline-unnecessary, but again is again mainly here as an example of some of the more-obvious validations
    create_demo_transform_validation!(
      transform: fact_parent_org_map_transform,
      validation: Validation.fk,
      params: { table_name: :mapped_facts, fk_table_name: :mapped_facts, fk_column_name: :clarity_school_parent_org_id, pk_table_name: :school_parent_mappings, pk_column_name: :clarity_org_id }
    )

    fact_school_org_map_transform = create_demo_transform!(
      name: "Mapped fact table clarity_school_org_id column-loader",
      sql: <<-SQL.strip_heredoc
        UPDATE mapped_facts AS mf
           SET clarity_school_org_id = sm.clarity_org_id
          FROM staging_facts sf, school_mappings sm
         WHERE mf.staging_fact_id = sf.id
           AND sf.school_code = sm.co_school_id
      SQL
    )

    create_demo_dependency!(prerequisite_transform: fact_initial_map_transform, postrequisite_transform: fact_school_org_map_transform)
    create_demo_dependency!(prerequisite_transform: school_mappings_initial_map_transform, postrequisite_transform: fact_school_org_map_transform)

    # This is borderline-unnecessary, but again is again mainly here as an example of some of the more-obvious validations
    create_demo_transform_validation!(
      transform: fact_school_org_map_transform,
      validation: Validation.fk,
      params: { table_name: :mapped_facts, fk_table_name: :mapped_facts, fk_column_name: :clarity_school_org_id, pk_table_name: :school_mappings, pk_column_name: :clarity_org_id }
    )

    # This fails b/c the source file doesn't have any valid school IDs ... but, it's still useful for seeing what validation errors look like.
    # create_demo_transform_validation!(
    #   transform: fact_school_org_map_transform,
    #   validation: Validation.non_null,
    #   params: { table_name: :mapped_facts, column_name: :clarity_school_org_id }
    # )

    # DataQualityReports for Mapping Transforms

    create_data_quality_report!(
      name: "School Mappings table count",
      sql: "SELECT count(1) FROM school_mappings"
    )

    create_data_quality_report!(
      name: "School Parent Mappings table count",
      sql: "SELECT count(1) FROM school_parent_mappings"
    )

    create_data_quality_report!(
      name: "Mapped Facts table count",
      sql: "SELECT count(1) FROM mapped_facts"
    )

    # Export Transform

    demo_workflow.reload
  end

  def create_demo_transform!(**options)
    Transform.where(name: options.delete(:name)).first_or_create!(options.merge(workflow: demo_workflow))
  end

  def create_demo_dependency!(**options)
    TransformDependency.where(options).first_or_create!
  end

  def create_demo_data_file!(**options)
    DataFile.where(name: options.delete(:name)).first_or_create!(options.merge(s3_bucket_name: 'bb-dpl-cms', customer: demo_customer))
  end

  def create_demo_transform_validation!(**options)
    TransformValidation.where(transform: options.delete(:transform), validation: options.delete(:validation)).first_or_create!(options)
  end

  def create_data_quality_report!(**options)
    DataQualityReport.where(name: options.delete(:name)).first_or_create!(options.merge(workflow: demo_workflow))
  end

end
