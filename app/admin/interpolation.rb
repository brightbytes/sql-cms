ActiveAdmin.register Interpolation do

  menu priority: 55

  actions :all

  permit_params :name, :slug, :sql

  filter :name, as: :string
  filter :slug, as: :string
  filter :sql, as: :string

  config.sort_order = 'name_asc'

  index(download_links: false) do
    column(:name) { |interpolation| auto_link(interpolation) }
    column('') { |interpolation| link_to("Edit", edit_interpolation_path(interpolation)) }
    column(:slug) { |interpolation| interpolation.slug }
    column('') do |interpolation|
      if interpolation.used?
        text_node("In Use")
      else
        link_to("Delete", interpolation_path(interpolation), method: :delete, data: { confirm: "Are you sure you want to nuke this Interpolation?" })
      end
    end
  end

  show do
    attributes_table do
      row :id
      row :name
      row :slug
      row :usage_count
      simple_format_row(:sql)
      row :created_at
      row :updated_at
    end

    transforms = resource.referencing_transforms.order(:name)
    if transforms.present?
      panel 'Transforms' do
        table_for(transforms) do
          column(:transform) { |transform| auto_link(transform) }
          column('') { |transform| text_node(link_to("Edit", edit_transform_path(transform))) }
          column(:runner)
          boolean_column(:enabled)
        end
      end
    end

    dqrs = resource.referencing_data_quality_reports.order(:name)
    if dqrs.present?
      panel 'Data Quality Report' do
        table_for(dqrs) do
          column(:data_quality_report) { |data_quality_report| auto_link(data_quality_report) }
          column('') { |data_quality_report| text_node(link_to("Edit", edit_data_quality_report_path(data_quality_report))) }
          boolean_column(:immutable)
          boolean_column(:enabled)
        end
      end
    end

    active_admin_comments

    render partial: 'admin/shared/history'
  end

  form do |f|
    inputs 'Details' do
      input :name, as: :string
      input :slug, as: :string, hint: "Must be lowercase, start with a letter, and can contain only letters, numbers, and underscores.  Use in Transforms as :slug:. Leave blank to auto-generate from name."
      input :sql, as: :text, input_html: { rows: 70 }
    end

    actions do
      action(:submit)
      cancel_link(f.object.new_record? ? interpolations_path : interpolation_path(f.object))
    end
  end

  controller do

    def action_methods
      result = super
      result -= ['destroy'] if action_name == 'show' && resource.used?
      result
    end

  end

end
