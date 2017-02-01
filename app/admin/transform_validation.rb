ActiveAdmin.register TransformValidation do

  menu false

  actions :destroy

  actions :new, :create, :destroy

  permit_params :transform_id, :validation_id, :params

  form do |f|
    # For debugging:
    # semantic_errors *f.object.errors.keys
    inputs 'Details' do
      input :transform_id, as: :hidden, input_html: { value: transform_id_param_val }
      input :transform, as: :select, collection: transforms_with_preselect, input_html: { disabled: true }
      input :validation, as: :select, collection: Validation.order(:name).all

      # FIXME - IT'S REALLY TOO BAD THIS LINE CAN'T BE MADE TO WORK LIKE THIS: https://lorefnon.me/2015/03/02/dealing-with-json-fields-in-active-admin.html
      #         (I TRIED, AND FAILED: DOESN'T WORK IN THE LATEST VERSION OF AA)
      input :params_yaml, as: :text
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

    def destroy
      super do |success, failure|
        # FIXME - PASS AN ARG INDICATING WHETHER TO GO BACK TO transform_path OR validation_path
        success.html { redirect_to(transform_path(resource.postrequisite_transform)) }
      end
    end
  end

end
