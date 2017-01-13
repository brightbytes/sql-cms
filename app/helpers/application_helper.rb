module ApplicationHelper

  def pretty_print_as_json(json)
    JSON.pretty_generate(json.as_json).gsub(/\"(.+)\":/, '\1:').gsub(" ", "&nbsp;").gsub("\n", "<br />").html_safe if json.present?
  end

  # Kinda lame, but whatever
  def pretty_print_json(json)
    pretty_print_as_json(JSON.parse(json))
  end

end
