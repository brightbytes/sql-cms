module WorkflowSeeder

  extend self

  def seed
    CustomerSeeder.seed
    workflow = Workflow.where(name: 'Public Data Workflow, version 1').first_or_create!(customer: Customer.where(name: CustomerSeeder::CUSTOMERS[1]).first)
    notify_me!(workflow)
    workflow = Workflow.where(name: 'SIS Data Workflow, version 1').first_or_create!(customer: Customer.where(name: CustomerSeeder::CUSTOMERS[0]).first)
    notify_me!(workflow)
  end

  private

  def notify_me!(workflow)
    workflow.notifications.first_or_create!(user: User.where(email: 'aaron@brightbytes.net').first)
  end

end
