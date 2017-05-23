# Encapsulates how a Transform works with a remote S3 File
class S3File

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

  attr_reader :atts, :s3_region_name, :s3_bucket_name, :s3_file_path, :s3_file_name

  def initialize(**atts)
    @atts = atts
    @s3_region_name = atts[:s3_region_name]
    @s3_bucket_name = atts[:s3_bucket_name]
    @s3_file_path = atts[:s3_file_path]
    @s3_file_name = atts[:s3_file_name]
  end

  def s3_file_extension
    @s3_file_extension ||=
      if s3_file_name.present?
        if match = /.+\.(.+)$/.match(s3_file_name)
          match[1].tap(&:downcase!)
        end
      end
  end

  TSV = 'tsv'

  def tsv?
    s3_file_extension == TSV
  end

  CSV = 'csv'

  def csv?
    s3_file_extension == CSV
  end

  def to_s
    "'s3://#{s3_bucket_name}/#{s3_file_path_and_name}' in region #{s3_region_name}"
  end

  private

  def s3
    # We put this here rather than in the base initializer so that the file extention stuff ^^ can be used without any other atts being set
    raise "Missing s3_region_name, s3_bucket_name, and/or s3_file_name: #{atts.inspect}" unless [s3_region_name, s3_bucket_name, s3_file_name].all?(&:present?)
    @s3 ||= Aws::S3::Resource.new(region: s3_region_name)
  end

  class S3ImportFile < S3File

    def s3_presigned_url
      @s3_presigned_url ||=
        begin
          exists = s3_object.exists?
          s3_object.presigned_url(:get) if exists
        rescue Aws::S3::Errors::Http301Error
          false
        end
    end

    def s3_object_valid?
      s3_object.exists?
      true
    rescue Aws::S3::Errors::Http301Error
      false
    end

    def s3_file_exists?
      !!s3_presigned_url
    end

    def s3_public_url
      @s3_public_url ||= s3_object.public_url if s3_object.exists?
    end

    private

    def s3_file_path_and_name
      "#{s3_file_path}/#{s3_file_name}".gsub(/\/{2,}/, '/')
    end

    def s3_object
      @s3_object ||
        begin
          s3_bucket = s3.bucket(s3_bucket_name)
          @s3_object = s3_bucket.object(s3_file_path_and_name)
        end
    end

  end

  class S3ExportFile < S3File

    attr_reader :run

    def initialize(**atts)
      super
      @run = atts[:run]
      raise "You must pass a Run instance!" unless @run.present?
    end

    def upload(stream)
      raise "No stream supplied!" unless stream.present?
      s3_object.put(body: stream)
    end

    private

    def s3_file_path_and_name
      "#{s3_file_path}/run_#{run.id}/#{s3_file_name}".gsub(/\/{2,}/, '/')
    end

    def s3_object
      @s3_object ||
        begin
          s3_bucket = s3.bucket(s3_bucket_name)
          @s3_object = s3_bucket.object(s3_file_path_and_name)
        end
    end

  end

end
