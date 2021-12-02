# frozen_string_literal: true

require 'open3'

# For shelling out to the command-line when you want an error therein to `raise`
module ShellCommand

  extend self

  # Each command may be a string or an array, the latter being useful for anti-injection
  # Accepts a `:quietly` keyword, which when `true` suppresses printout of the command and its STDOUT to the console
  # If the command's status isn't `success`, raises with the message set to the contents of STDERR, unless `:continue_on_fail` is `true`,
  #  in which case it returns whatever was emitted to STDOUT up to that point
  def run(*cmds)
    options = cmds.extract_options!
    quietly = options[:quietly]
    continue_on_fail = options[:continue_on_fail]
    Dir.chdir(Rails.root) # not sure this is actually useful

    result = cmds.map do |cmd|
      cmd = Array(cmd).map(&:to_s)
      unless quietly
        printed_cmd = cmd.join(' ')
        puts "==> \`#{printed_cmd}\`"
      end

      stdout_s, stderr_s, status = Open3.capture3(*cmd)

      if status.success?
        puts stdout_s unless quietly
        stdout_s.strip
      elsif continue_on_fail
        puts stdout_s, stderr_s unless quietly
        stdout_s.strip
      else
        raise stderr_s
      end
    end

    result.size > 1 ? result : result.last
  end

  def run_quietly(*cmds)
    options = cmds.extract_options!
    options.merge!(quietly: true)
    run(*cmds, options)
  end

end
