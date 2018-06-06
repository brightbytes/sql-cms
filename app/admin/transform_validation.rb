ActiveAdmin.register TransformValidation do

  menu false

  actions :all, except: :index

  permit_params :transform_id, :validation_id, :params_yaml, :enabled

  show title: :interpolated_name do
    attributes_table do
      row :id
      row :transform
      row :validation
      row :interpolated_name if resource.params.present? && resource.name != resource.interpolated_name
      boolean_row :enabled
      code_format_row(:params_yaml)
      code_format_row(:transform_params_yaml)
      code_format_row(:sql)
      code_format_row(:interpolated_sql) if resource.sql != resource.interpolated_sql
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
      input :transform, as: :select, collection: [[resource.transform.name, resource.transform.id, selected: true]], input_html: { disabled: true }
      input :validation, as: :select, collection: Validation.order(:name).all

      input :params_yaml, as: :text, required: true
      input :transform_params_yaml, as: :text, collection: resource.transform.params_yaml, input_html: { disabled: true }, hint: "These params will be reverse-merged into the params_yaml in the previous field: there's no need to type them again."

      input :enabled, hint: "Unchecking this causes this TransformValidation to be skipped during a Run "
    end

    actions do
      action(:submit)
      cancel_link(parent_transform_path)
    end
  end

  controller do

    def new
      @transform_validation = TransformValidation.new(transform_id: transform_id_param_val)
    end

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
        success.html { redirect_to(params[:source] == 'validation' ? validation_path(resource.validation) : parent_transform_path) }
      end
    end
  end

end
