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

  def create_demo_workflow!
    workflow = Workflow.where(name: 'Demo Workflow, version 1').first_or_create!(customer: Customer.where(name: CustomerSeeder::CUSTOMERS[2]).first)

    staging_boces_mappings_table_transform = create_demo_transform!(
      name: "CREATE TABLE staging_boces_mappings",
      runner: 'RailsMigration',
      workflow: workflow,
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
      workflow: workflow,
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
      workflow: workflow,
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
      workflow: workflow,
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
      workflow: workflow,
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
      workflow: workflow,
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

    school_parent_mappings_table_transform = create_demo_transform!(
      name: "CREATE TABLE school_parent_mappings",
      runner: 'RailsMigration',
      workflow: workflow,
      sql: <<-SQL.strip_heredoc
        create_table :school_parent_mappings do |t|
          t.integer :staging_school_parent_mapping_id, null: false
          t.string :staging_school_parent_mapping_type
          t.integer :clarity_org_id, index: true
          t.integer :co_org_id, index: true
        end
        add_index :school_mappings, [:staging_school_parent_mapping_id, :staging_school_parent_mapping_type], unique: true, name: :index_school_parent_mappings_on_staging_school_parent_mapping_id_type
      SQL
    )

    mapped_facts_table_transform = create_demo_transform!(
      name: "CREATE TABLE mapped_facts",
      runner: 'RailsMigration',
      workflow: workflow,
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

    reduced_facts_table_transform = create_demo_transform!(
      name: "CREATE TABLE reduced_facts",
      runner: 'RailsMigration',
      workflow: workflow,
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

    workflow
  end

  def create_demo_transform!(**options)
    Transform.where(name: options.delete(:name)).first_or_create!(options)
  end



end
