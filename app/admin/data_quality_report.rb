ActiveAdmin.register DataQualityReport do

  menu priority: 50

  actions :all

  permit_params :name, :sql, :immutable

  filter :name, as: :string
  filter :sql, as: :string
  filter :immutable

  config.sort_order = 'name_asc'

  index(download_links: false) do
    column(:name) { |dqr| auto_link(dqr) }
    boolean_column(:immutable)
    column(:used_by_count) { |dqr| dqr.usage_count }
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
