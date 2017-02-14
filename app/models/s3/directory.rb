class S3::Directory

  attr_reader :path

  def initialize(bucket: , path: nil)
    @bucket = bucket
    @path = path
  end

  def name
    path_pieces.last
  end

  def parent
    parent_path = path_pieces[0..-2].join('/')
    S3::Directory.new(@bucket, parent_path) unless parent_path.blank?
  end

  def children
    subdirectories + files
  end

  def subdirectories
    @subdirectories ||= list_objects['common_prefixes'].collect do |prefix|
      S3::Directory.new(@bucket, prefix.prefix)
    end
  end

  def files
    @files ||= list_objects['contents'].collect do |object|
      S3::File.new(@bucket, s3_object: object) unless object.key.ends_with?('/')
    end.compact
  end

  private

  def path_pieces
    @path_pieces ||= path ? path.split('/') : []
  end

  def list_objects
    @list_objects ||= @bucket.client.list_objects(
      prefix: @path.blank? ? '' : "#{@path}/",
      delimiter: '/',
      bucket: @bucket.name,
      encoding_type: 'url'
    )
  end

  class << self

    def root_directory(s3_region_name: 'us-west-2', s3_bucket_name:)
      s3_bucket = s3.bucket(s3_bucket_name)
      new(bucket: s3_bucket)
    end

    private def s3(s3_region_name = 'us-west-2')
      Aws::S3::Resource.new(region: s3_region_name)
    end

  end

end
