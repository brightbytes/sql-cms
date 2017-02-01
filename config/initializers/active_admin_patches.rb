module ActiveAdmin::ViewHelpers
  include ApplicationHelper
end

class ActiveAdmin::BaseController
  include ApplicationHelper
end

module ActiveAdmin::Views

  class TableFor
    def boolean_column(attribute)
      att_name = attribute.to_s.humanize.titleize
      att_name += "?" unless att_name.ends_with?('?')
      column(att_name) do |model|
        value =
          if block_given?
            yield model
          else
            attr = !model.respond_to?(attribute) && !attribute.to_s.ends_with?('?') ? :"#{attribute}?" : attribute
            model.send(attr)
          end
        value ? 'Yes' : 'No'
      end
    end
  end

  class AttributesTable
    def boolean_row(attribute)
      att_name = attribute.to_s.humanize.titleize
      att_name += "?" unless att_name.ends_with?('?')
      row(att_name) do |model|
        value =
          if block_given?
            yield model
          else
            attr = !model.respond_to?(attribute) && !attribute.to_s.ends_with?('?') ? :"#{attribute}?" : attribute
            model.send(attr)
          end
        value ? 'Yes' : 'No'
      end
    end

    def simple_format_row(attribute)
      row(attribute) do |model|
        if val = model.send(attribute)
          simple_format(val)
        end
      end
    end
  end
end

# Patch for sorting sub-menus
class ActiveAdmin::Views::TabbedNavigation
  def priority_for(item)
    item.children.values.map(&:priority).min || item.priority
  end
  private :priority_for

  def menu_items
    menu.items(self).sort { |i1, i2| priority_for(i1) <=> priority_for(i2) }
  end
end

# Footer Section - patch because the new way doesn't work
class ActiveAdmin::Views::Pages::Base < Arbre::HTML::Document
  private
  # Renders the content for the footer
  def build_footer
    div id: "footer" do
      para "Copyright &copy; #{Date.today.year.to_s} BrightBytes Inc.".html_safe
    end
  end
end

# Redo of Comment form, putting form at top and past comments reversed at the bottom, and adding edit and destroy links to the body
# FIXME: THIS WILL PROBABLY FAIL WITH EACH UPDATE, SO BE READY TO UPDATE IT FROM THE LATEST GEM SOURCE
# FIXME: THE LATEST VERSION OF AA NO LONGER SUPPORTS EDITING COMMENTS; WTF?!
module ActiveAdmin
  module Comments
    module Views
      class Comments < ActiveAdmin::Views::Panel
        def build_comments
          build_comment_form
          @comments.any? ? @comments.reverse_each(&method(:build_comment)) : build_empty_message
        end

        def build_comment(comment)
          div for: comment do
            div class: 'active_admin_comment_meta' do
              h4 class: 'active_admin_comment_author' do
                comment.author ? auto_link(comment.author) : I18n.t('active_admin.comments.author_missing')
              end
              span pretty_format comment.created_at
              # Since we're all logging on as the same User, comment this out, for now.
              # if authorized?(ActiveAdmin::Auth::DESTROY, comment)
              #   text_node link_to I18n.t('active_admin.comments.delete'), comments_url(comment.id), method: :delete, data: { confirm: 'Are you sure you want to delete this comment?' }
              # end
            end
            div class: 'active_admin_comment_body' do
              simple_format comment.body
            end
          end
        end

      end
    end
  end
end
