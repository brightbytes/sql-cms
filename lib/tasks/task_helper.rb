require 'csv'
require 'highline'

# This should be automatic ... but isn't; WTF?!?!?!!
require "#{Rails.root}/config/initializers/dputs"

module TaskHelper

  extend self

  def load_yaml_data(name)
    path = Rails.root + "config/data/#{name}.yml"
    HashWithIndifferentAccess.new(YAML.load(File.read(path)))
  end

  SLACK_DEPLOYMENT_CHANNEL = '#engineering-deploylog'.freeze
  SLACK_ENGINEERING_CHANNEL = '#engineering-hub'.freeze

  def chat_broadcast(msg, phase:, notify: false)
    raise "You must add the SLACK_WEBHOOK to your environment!" unless slack_hook

    attachment = [
      {
        fallback: "Deploying to #{phase}",
        color: "good",
        fields: [
          {
            title: "Details",
            value: decorate_msg(msg),
            short: false
          }
        ]
      }
    ]

    slack.ping("*Deploying to #{phase}*", attachments: attachment, channel: SLACK_DEPLOYMENT_CHANNEL)
    slack.ping("*Deploying to #{phase}*", attachments: attachment, channel: SLACK_ENGINEERING_CHANNEL) if notify
  end

  def decorate_msg(msg)
    msg.gsub("(channel)", "<!channel>").gsub("(branch)", "").gsub("(continue)", "").gsub("(successful)", ":rocket:").gsub("(hisham)", ":hisham:").gsub("(jusx)", ":jusx:")
  end

  def slack
    @slack ||= Slack::Notifier.new(slack_hook)
  end

  def slack_hook
    @slack_hook ||= ENV["SLACK_WEBHOOK"]
  end

  def run(*cmds)
    dry_run = ENV['DRY_RUN']
    Dir.chdir(Rails.root)
    result = cmds.map do |cmd|
      cmd_s = "==> \`#{cmd}\`"
      if dry_run
        puts "DRY RUN ONLY"
        puts cmd_s
      else
        with_timing(cmd_s) { `#{cmd}` || raise("System call failed: #{cmd.inspect}") }
      end
    end
    result.last.try(:strip) unless dry_run
  end

  def ask(prompt, show_abort_message: true, required_response: 'yes', important: false)
    msg = prompt + (show_abort_message ? " Typing anything other than '#{required_response}' will abort." : " You must type #{required_response} to do so.")
    if important # Color important text RED and highlight the required response
      msg = "\e[31m#{msg}\e[0m"
      msg.sub!(/'#{required_response}'/, "\e[47m'#{required_response}'\e[49m")
    end
    HighLine.new.ask(msg) =~ /\A#{required_response}\Z/i
  end

  def current_branch
    # I don't know sed at all, hence I don't know which backslashes need to be doubled and which don't :(
    cmd = 'git branch 2> /dev/null | sed -e \'/^[^*]/d\' -e \'s/* \(.*\)/\1/\''
    result = `#{cmd}`
    raise "Unable to get the current branch name" if result.blank?
    result.strip
  end

  def do_push(branch)
    puts "Pushing #{branch} to origin ..."
    puts `git push origin #{branch} -u`
  end

  def with_timing(what)
    start = Time.now
    puts "Commencing #{what} ..."
    result = yield
    time = Time.at(Time.now - start).getutc.strftime("%H:%M:%S")
    puts
    puts "Finished #{what} in #{time}."
    result
  end

end
