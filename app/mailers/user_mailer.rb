class UserMailer < ApplicationMailer

  def run_completed(run)
    @run = run
    @workflow = @run.workflow
    @recipients = @workflow.rfc_email_addresses_to_notify
    base_text = "Your run '#{@run}' "
    @h1_text = base_text + (@run.successful? ? "succeeded admirably" : "failed miserably")

    mail(to: @recipients, subject: @h1_text)
  end

end
