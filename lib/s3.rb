# Wrapper for the logic behind the S3 service.
class S3

  def initialize(id, key, region)
    @id = id
    @key = key
    Aws.config[:credentials] = Aws::Credentials.new(@id, @key)
    @region = region
  end

  # Uses the `acl.txt` file in the bucket to see who has access.
  #   s3.can_read? "homer@springfield.com", "mybucket"
  #   => false
  def can_read?(email, bucket)
    s3 = Aws::S3::Client.new(region: 'us-west-2' )
    resp = s3.get_object(bucket: bucket, key: "acl.txt")
    acl = resp.body.read.split("\n")
    acl.include?(email)
  end

  # retrieves all objects in the bucket except our acl.txt file.
  def get_all_objects_in(bucket)
    s3 = Aws::S3::Resource.new(region: @region )
    bucket = s3.bucket(bucket)
    bucket.objects.reject{|o| o.key == "acl.txt"}
  end

  #
  def get_object_with_url_by_key(key, timeout)
    s3 = Aws::S3::Resource.new(region: @region )
    bucket = s3.bucket(bucket)
    object = bucket.object(key)
    timeout = timeout.to_i
    url = object.presigned_url(:get, { expires_in: (timeout * 60), secure: true })
    {url: url, content_type: object.content_type, name: object.key}
  end
end
