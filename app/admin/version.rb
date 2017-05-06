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
      row(:changeset) { |v| code(pretty_print_as_json(v.changeset)) }
    end
  end
end
