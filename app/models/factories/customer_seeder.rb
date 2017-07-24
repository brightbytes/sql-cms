module CustomerSeeder

  extend self

  CUSTOMERS = ["Fake Customer"]

  def seed
    CUSTOMERS.each { |name| Customer.where(name: name).first_or_create! }
  end

  def demo_customer
    Customer.where(name: CustomerSeeder::CUSTOMERS[0]).first
  end

end
