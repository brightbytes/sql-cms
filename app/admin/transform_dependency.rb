ActiveAdmin.register TransformDependency do

  menu false

  actions :destroy

  controller do

    def destroy
      super do |success, failure|
        success.html { redirect_to(transform_path(params[:source] == 'postrequisite_transform' ? resource.postrequisite_transform : resource.prerequisite_transform)) }
      end
    end
  end

end
