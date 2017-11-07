ActiveAdmin.register PaperTrail::Version do

  menu false

  actions :show

  show do
    attributes_table do
      row("Version ID", &:id)
      row("Item") { auto_link(resource.item) }
      row("Item Version Number") { |v| "#{v.item.versions.index(v) + 1}." }
      row(:event) { |v| v.event.titleize }
      row("Modified at") { |v| v.created_at.localtime.to_s }
      row("Modified by") do |v|
        if v.user_id
          if u = User.find_by(id: v.user_id)
            link_to(u.full_name, user_path(u))
          else
            "**Deleted**"
          end
        else
          "Script or Job"
        end
      end
      row('Changed Attributes', &:changed_attributes)
      row(:changeset) { |v| code(pretty_print_as_json(v.changeset)) }
    end
  end

  # Undoing a `create` will delete the object.
  sidebar("Actions", only: :show, if: proc { resource.event != 'create' }) do
    ul do
      li link_to("Undo All Changeset Changes", revert_paper_trail_version_path(resource), method: :put)
    end
  end

  member_action :revert, method: :put do
    resource.reify&.save!
    flash[:notice] = "Reverted the Item per the Changeset of this Version"
    redirect_to paper_trail_version_path(resource)
  end
end
