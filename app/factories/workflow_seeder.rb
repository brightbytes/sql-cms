module WorkflowSeeder

  extend self

  def seed
    CustomerSeeder.seed
    [
      Workflow.where(name: 'Public Data Workflow, version 1').first_or_create!(customer: Customer.where(name: CustomerSeeder::CUSTOMERS[1]).first),
      Workflow.where(name: 'SIS Data Workflow, version 1').first_or_create!(customer: Customer.where(name: CustomerSeeder::CUSTOMERS[0]).first)#,
      # create_demo_workflow!
    ].each { |workflow| notify_me!(workflow) }
  end

  private

  def notify_me!(workflow)
    workflow.notifications.first_or_create!(user: User.where(email: 'aaron@brightbytes.net').first)
  end

  def create_demo_workflow!
    workflow = Workflow.where(name: 'Demo Workflow, version 1').first_or_create!(customer: Customer.where(name: CustomerSeeder::CUSTOMERS[2]).first)
    staging_boces_mappings_table_transform = Transform.create!(
      name: "CREATE TABLE staging_boces_mappings",
      runner: 'RailsMigration',
      workflow: workflow

    )

  end



end
