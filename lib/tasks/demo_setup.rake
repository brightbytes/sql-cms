# frozen_string_literal: true

require "#{Rails.root}/lib/tasks/task_helper"

namespace :demo do

  include TaskHelper

  desc "Uploads the demo files to the specified s3://bucket/path/to/files/ prefix. Requires installation of the AWS Commandline tools."

  task :upload_to_s3, [:s3_url] => :environment do |t, args|

    s3_url = args.s3_url.presence
    raise "You must provide an S3 URL of the form s3://bucket/path/to/files/" unless s3_url

    s3_url += '/' unless s3_url.ends_with?('/')

    Dir.glob(File.join(Rails.root, "spec/fixtures/files/*.csv")).each do |source_file|
      run("aws s3 cp #{source_file} #{s3_url}")
    end

  end

end