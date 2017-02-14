# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview

  def run_completed
    if run = WorkflowSeeder.demo_workflow.runs.order(:id).last
      UserMailer.run_completed(run)
    else
      raise "You'll need to generate a Run for the Demo Workflow before you can use this feature!"
    end
  end

end
