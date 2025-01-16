# Wrapper for the logic behind the S3 service.
class S3

  # Create an instance using the id, key, bucket, region, and optional endpoint
  def initialize(id, key, bucket, region, endpoint=nil)
    @id     = id
    @key    = key
    @bucket = bucket
    @region = region

    Aws.config[:credentials] = Aws::Credentials.new(@id, @key)
    Aws.config[:region]      = @region

    if endpoint
      Aws.config[:endpoint]         = endpoint
      Aws.config[:force_path_style] = true
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
  #   s3.can_read_with_password? "homer@springfield.com", "12345
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

  # Retrieves all objects in the bucket except our acl.txt file.
  #
  # We do NOT convert these files into full Aws::S3::Object calls.
  # That avoids HEAD requests. We only rely on what list_objects_v2
  # gives key, size, and last_modified.
  #
  # Returns [folders, files], where:
  #   folders = array of folder prefixes,  e.g. ["photos/", "docs/"]
  #   files   = array of summary-hashes,   e.g.
  #             [
  #               { key: "image1.jpg", size: 12345, last_modified: <Time> },
  #               ...
  #             ]
  #
  def list(prefix = "", options = {})
    # Normalize the prefix
    prefix = prefix.sub(/^\/+/, "")
    prefix << "/" if !prefix.empty? && !prefix.end_with?("/")

    s3_resource = Aws::S3::Resource.new
    bucket_obj  = s3_resource.bucket(@bucket)

    resp = bucket_obj.client.list_objects_v2(
      bucket:    @bucket,
      prefix:    prefix,
      delimiter: "/"
    )

    # Subfolders => resp.common_prefixes
    folders = if options[:hide_folders]
                puts "got here"
                []
              else
                resp.common_prefixes.map { |cp| cp.prefix }
              end

    # Files => resp.contents (these are object *summaries*).
    #    We'll skip 'acl.txt'
    #    Each summary has .key, .content_length, .last_modified
    files = resp.contents.reject { |c| c.key == "acl.txt" }.map do |summary|
      {
        key:            summary.key,
        content_length: summary.size,
        last_modified: summary.last_modified
      }
    end

    [folders, files]
  end

  # Check if something is a folder
  #
  # We do a small list_objects_v2(prefix: "key/") with max_keys=1.
  # If we get anything back, it’s considered a folder.
  def is_folder?(key)
    key = key.sub(/^\/+/, "")
    candidate_prefix = key.end_with?("/") ? key : "#{key}/"

    s3_resource = Aws::S3::Resource.new
    resp = s3_resource.bucket(@bucket).client.list_objects_v2(
      bucket:   @bucket,
      prefix:   candidate_prefix,
      max_keys: 1
    )

    resp.key_count > 0
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

    expires_in_seconds = timeout.to_i * 60
    url = object.presigned_url(:get, expires_in: expires_in_seconds, secure: true)

    {
      url:            url,
      content_type:   object.content_type,    # triggers HEAD if not cached
      name:           object.key,
      content_length: object.content_length,  # triggers HEAD if not cached
      last_modified:  object.last_modified
    }
  end
end
