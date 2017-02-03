class RunManagerJob < ApplicationJob

  queue_as :default

  def perform(run)

  end
end
