ActiveAdmin.register TransformDependency do

  menu false

  actions :destroy

  controller do

    def destroy
      super do |success, failure|
        success.html { redirect_to(transform_path(resource.postrequisite_transform)) }
      end
    end
  end

end
