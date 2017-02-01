ActiveAdmin.register TransformValidation do

  menu false

  actions :destroy

  controller do

    def destroy
      super do |success, failure|
        # FIXME - PASS AN ARG INDICATING WHETHER TO GO BACK TO transform_path OR validation_path
        success.html { redirect_to(transform_path(resource.postrequisite_transform)) }
      end
    end
  end

end
