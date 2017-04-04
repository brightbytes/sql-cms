ActiveAdmin.register TransformValidation do

  menu false

  actions :all, except: :index

  permit_params :transform_id, :validation_id, :params_yaml

  show title: :interpolated_name do
    attributes_table do
      row :id
      row :transform
      row :validation
      row(:params) { code(pretty_print_as_json(resource.params)) }
      row :interpolated_name
      simple_format_row(:sql)
      simple_format_row(:interpolated_sql) if resource.params.present?
      row(:validation_immutable) { yes_no(resource.validation.immutable) }
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    # For debugging:
    semantic_errors *f.object.errors.keys
    inputs 'Details' do
      input :transform_id, as: :hidden, input_html: { value: transform_id_param_val }
      input :transform, as: :select, collection: [[resource_transform.name, resource_transform.id, selected: true]], input_html: { disabled: true }
      input :validation, as: :select, collection: Validation.order(:name).all

      # FIXME - IT'S REALLY TOO BAD THIS LINE CAN'T BE MADE TO WORK LIKE THIS: https://lorefnon.me/2015/03/02/dealing-with-json-fields-in-active-admin.html
      #         (I TRIED, AND FAILED: DOESN'T WORK IN THE LATEST VERSION OF AA)
      input :params_yaml, as: :text, required: true
    end
    actions do
      action(:submit)
      cancel_link(parent_transform_path)
    end
  end

  controller do

    def create
      super do |success, failure|
        success.html { redirect_to(parent_transform_path) }
      end
    end

    def update
      super do |success, failure|
        success.html { redirect_to(parent_transform_path) }
      end
    end

    def destroy
      super do |success, failure|
        success.html { redirect_to(parent_transform_path) }
      end
    end
  end

end
