# Wrapper for the logic behind the S3 service.
class S3

  # Create an instance using the id, key, bucket, region, and optional endpoint
  def initialize(id, key, bucket, region, endpoint=nil)
    @id = id
    @key = key
    @bucket = bucket
    @region = region
    # TODO: fix this - pass creds directly.
    Aws.config[:credentials] = Aws::Credentials.new(@id, @key)
    Aws.config[:region] = @region
    if endpoint
      Aws.config[:endpoint] = endpoint
    end

  end

  # Uses the `acl.txt` file in the bucket to see who has access.
  #   s3.can_read? "homer@springfield.com"
  #   => false
  def can_read?(email)
    acl.include?(email)
  end

  # Uses the `acl.txt` file in the bucket to see who has access.
  # Called by basic auth.
  # The `acl.txt` file should have a user and password in the format
  #
  #     homer@example.com:12345
  #
  # Usage:
  #   s3.can_read_with_password? "homer@springfield.com", "12345"
  #   => false
  def can_read_with_password?(email, password)
    acl.detect do |a|
      entry = a.split(":")
      entry.first == email && entry.last == password
    end
  end

  def acl
    s3 = Aws::S3::Client.new
    begin
      resp = s3.get_object(bucket: @bucket, key: "acl.txt")
      resp.body.read.split("\n")
    #rescue Aws::S3::Errors::NoSuchBucket
    #  []
    rescue Aws::S3::Errors::NoSuchKey
      []
    end

  end

  # retrieves all objects in the bucket except our acl.txt file.
  def get_all_objects
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket(@bucket)
    bucket.objects.reject{|o| o.key == "acl.txt"}
  end

  # Get the object data from S3 by the key, returning the following hash:
  #   {
  #     url: S3 secure URL that times out,
  #     content_type: the MIME type,
  #     name: the object's name (the key)
  #   }
  def get_object_data_by_key(key, timeout)
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket(@bucket)
    object = bucket.object(key)
    timeout = timeout.to_i
    url = object.presigned_url(:get, { expires_in: (timeout * 60), secure: true })
    {url: url, content_type: object.content_type, name: object.key}
  end
end
