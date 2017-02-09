ActiveAdmin.register_page "Dashboard" do

  menu priority: 1, label: proc{ I18n.t("active_admin.dashboard") }

  content title: proc{ I18n.t("active_admin.dashboard") } do

    columns do

      column do
        panel "Quick Links" do
          ul do
            li link_to("Sidekick Monitoring", sidekiq_web_path, target: :blank)
          end
        end
      end

      column do
        panel "Recent Runs" do
          ul do
            Run.order(id: :desc).limit(10).map do |run|
              li link_to(run, run_path(run))
            end
          end
        end
      end

    #   column do
    #     panel "Links" do
    #       para "Welcome to ActiveAdmin."
    #     end
    #   end

    end
  end # content
end
