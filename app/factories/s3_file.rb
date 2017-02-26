# Encapsulates how a Transform works with a remote S3 File
class S3File

  attr_accessor :s3_region_name, :s3_bucket_name, :s3_file_path, :s3_file_name

  def initialize(**atts)
    @s3_region_name = atts[:s3_region_name]
    @s3_bucket_name = atts[:s3_bucket_name]
    @s3_file_path = atts[:s3_file_path]
    @s3_file_name = atts[:s3_file_name]
    raise "Missing s3_region_name, s3_bucket_name, and/or s3_file_name: #{atts.inspect}" unless [s3_region_name, s3_bucket_name, s3_file_name].all?(&:present?)
  end

  class << self
    def create(type = 'import', **atts)
      case type
      when 'import'
        S3ImportFile.new(atts)
      when 'export'
        S3ExportFile.new(atts)
      else
        raise "Unknown S3 File Type: #{type}"
      end
    end
  end

  class S3ImportFile < S3File

    def s3_presigned_url
      @s3_presigned_url ||= s3_object.presigned_url(:get) if s3_object.exists?
    end

    def s3_file_exists?
      !!s3_presigned_url
    end

    def s3_public_url
      @s3_public_url ||= s3_object.public_url if s3_object.exists?
    end

    private

    def s3_object
      @s3_object ||
        begin
          s3_bucket = s3.bucket(s3_bucket_name)
          @s3_object = s3_bucket.object("#{s3_file_path}/#{s3_file_name}")
        end
    end

  end

  class S3ExportFile < S3File

    attr_accessor :run

    def initialize(**atts)
      super
      @run = atts[:run]
      raise "You must pass a Run instance!" unless @run.present?
    end

    def s3_object
      @s3_object ||
        begin
          s3_bucket = s3.bucket(s3_bucket_name)
          @s3_object = s3_bucket.object("#{s3_file_path}/run_#{run.id}/#{s3_file_name}")
        end
    end

  end

  private

  def s3
    @s3 ||= Aws::S3::Resource.new(region: s3_region_name)
  end

end
