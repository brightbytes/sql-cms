class S3::File

  attr_reader :path

  def initialize(bucket:, path:)
    @bucket = bucket
    @path = path
  end

  def name
    @name ||= ::File.basename(@path)
  end

  def extension
    @extension ||= ::File.extname(@path)
  end

  def directory
    @directory ||=
      begin
        dir = ::File.dirname(path)
        dir = nil if dir == '.'
        S3::Directory.new(@bucket, dir)
      end
  end

  def s3_object
    @s3_object ||= @bucket.object(@path)
  end

end
