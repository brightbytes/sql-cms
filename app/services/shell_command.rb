# frozen_string_literal: true

require 'open3'

# For shelling out to the command-line when you want an error therein to `raise`
module ShellCommand

  extend self

  def run(*cmds)
    options = cmds.extract_options!
    quietly = options[:quietly]
    Dir.chdir(Rails.root)
    result = cmds.map do |cmd|
      puts "==> \`#{cmd}\`" unless quietly
      stdout_s, stderr_s, status = Open3.capture3(cmd)
      if status.success?
        puts stdout_s unless quietly
        stdout_s.strip
      else
        raise stderr_s
      end
    end
    result.size > 1 ? result : result.last
  end

end
