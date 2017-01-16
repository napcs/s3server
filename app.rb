require 'sinatra/base'
require 'aws-sdk'
require 'dotenv/load'

require_relative "lib/s3"

class S3Server < Sinatra::Base

  get "/" do
    s3 = S3.new ENV["S3_ID"], ENV["S3_KEY"], ENV["S3_REGION"]
    @objects = s3.get_all_objects_in(ENV["S3_BUCKET"])
    erb :index
  end

  get "/o/:key" do
    s3 = S3.new ENV["S3_ID"], ENV["S3_KEY"], ENV["S3_REGION"]
    @data = s3.get_object_with_url_by_key(params[:key], ENV["S3_LINK_TIMEOUT"])
    erb :show
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end
