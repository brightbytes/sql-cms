ActiveAdmin.register DataQualityReport do

  menu priority: 50

  actions :all

  permit_params :name, :sql, :immutable

  filter :name, as: :string
  filter :sql, as: :string
  filter :immutable

  config.sort_order = 'name_asc'

  index(download_links: false) do
    column(:name) { |data_quality_report| auto_link(data_quality_report) }
    column('') { |data_quality_report| link_to("Edit", edit_data_quality_report_path(data_quality_report)) unless data_quality_report.immutable? }
    boolean_column(:immutable)
    column(:used_by_count) { |data_quality_report| data_quality_report.usage_count }
    column('') do |data_quality_report|
      unless data_quality_report.immutable?
        if data_quality_report.used?
          text_node("Remove usage to Delete")
        else
          link_to("Delete", data_quality_report_path(data_quality_report), method: :delete, data: { confirm: "Are you really sure you want to nuke this Data Quality Report?" })
        end
      end
    end
  end

  show do
    attributes_table do
      row :id
      row :name
      row :immutable
      row :usage_count
      simple_format_row(:sql)
      row :created_at
      row :updated_at
    end

    panel 'Workflows' do
      table_for(resource.workflow_data_quality_reports.includes(:workflow).order('workflows.name')) do
        column(:workflow)
        column(:workflow_data_quality_report) { |wdqr| link_to(wdqr.interpolated_name, wdqr) }
        boolean_column(:enabled)
        column('') do |wdqr|
          link_to("Delete", workflow_data_quality_report_path(wdqr, source: :data_quality_report), method: :delete, data: { confirm: 'Are you sure you want to nuke this Workflow Data Quality Report association?' })
        end
      end
    end

    active_admin_comments

    render partial: 'admin/shared/history'
  end

  form do |f|
    inputs 'Details' do
      input :name, as: :string
      input :sql, as: :text
      input :immutable, input_html: { disabled: f.object.immutable? }, hint: "Checking this indicates that this Data Quality Report should not and can not be altered"
    end

    actions do
      action(:submit)
      cancel_link(f.object.new_record? ? data_quality_reports_path : data_quality_report_path(f.object))
    end
  end

  controller do

    def action_methods
      result = super
      result -= ['edit', 'update', 'destroy'] if action_name == 'show' && resource.immutable?
      result
    end

  end

end
