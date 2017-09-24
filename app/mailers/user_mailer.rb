class UserMailer < ApplicationMailer

  helper do
    def report_headers(log)
      @report_headers ||= {}
      @report_headers[log.id] ||= log.step_result.first
    end

    def report_body(log)
      @report_body ||= {}
      @report_body[log.id] ||= log.step_result[1..-1]
    end
  end

  def run_completed(run)
    @run = run
    @recipients = @run.execution_plan[:rfc_email_addresses_to_notify]
    base_text = "Your run '#{@run}' "
    @h1_text = base_text + (@run.successful? ? "succeeded admirably" : @run.failed? ? "failed miserably" : "is still in progress, so you shouldn't be getting this email")

    mail(to: @recipients, subject: @h1_text)
  end

end
