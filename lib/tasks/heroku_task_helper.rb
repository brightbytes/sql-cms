require "#{Rails.root}/lib/tasks/task_helper"

module HerokuTaskHelper

  include TaskHelper

  def get_heroku_variable(phase, var_name)
    @heroku_env_vars ||= {}
    return @heroku_env_vars[var_name] if @heroku_env_vars[var_name]
    if token = heroku_run("heroku config:get #{var_name} --remote #{phase}").chomp.presence
      @heroku_env_vars[var_name] = token.split.last
    else
      raise "Ack! Thbbft!!! Can't find #{var_name} on heroku #{phase}."
    end
    @heroku_env_vars[var_name]
  end

  def heroku_run(*cmds)
    # Heroku Toolbelt uses Ruby 1.9, which requires clearing the RUBYOPT var ...
    run(*cmds.map { |cmd| cmd =~ /heroku/ ? "export RUBYOPT='' && #{cmd}" : cmd })
  end

end
