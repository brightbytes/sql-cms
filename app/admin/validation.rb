ActiveAdmin.register Validation do

  menu priority: 40

  actions :all

  permit_params :name, :sql, :immutable

  filter :name, as: :string
  filter :sql, as: :string
  filter :immutable

  config.sort_order = 'name_asc'

  index(download_links: false) do
    column(:name) { |validation| auto_link(validation) }
    column('') { |validation| link_to("Edit", edit_validation_path(validation)) unless validation.immutable? }
    boolean_column(:immutable)
    column(:used_by_count) { |validation| validation.usage_count }
    column('') do |validation|
      unless validation.immutable?
        if validation.used?
          text_node("Remove usage to Delete")
        else
          link_to("Delete", validation_path(validation), method: :delete, data: { confirm: "Are you really sure you want to nuke this Validation?" })
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

    panel 'Transform Validations' do
      table_for(resource.transform_validations.includes(:transform).order('transforms.name')) do
        column(:transform) { |tv| auto_link(tv.transform) }
        column(:runner) { |tv| tv.transform.runner }
        column(:transform_enabled) { |tv| yes_no(tv.transform.enabled?) }
        column(:transform_validation) { |tv| link_to(tv.interpolated_name, tv) }
        column('') do |tv|
          link_to("Delete", transform_validation_path(tv, source: :validation), method: :delete, data: { confirm: 'Are you sure you want to nuke this Transform Validation association?' })
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
      input :immutable, input_html: { disabled: f.object.immutable? }, hint: "Checking this indicates that this Validation should not and can not be altered"
    end

    actions do
      action(:submit)
      cancel_link(f.object.new_record? ? validations_path : validation_path(f.object))
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
