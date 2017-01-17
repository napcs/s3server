require 'sinatra/base'
require 'aws-sdk'
require 'dotenv/load'
require 'omniauth-oauth2'
require 'omniauth-google-oauth2'
require "sinatra/reloader"

require 'pp'
require_relative "lib/s3"


class S3Server < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

  use Rack::Session::Cookie, key: "S3Server", path: "/", secret: ENV['S3SERVER_SECRET_KEY']

  use OmniAuth::Builder do
    provider :google_oauth2, ENV["GOOGLE_ID"], ENV['GOOGLE_SECRET']
  end

  get "/" do
    redirect "/auth/google_oauth2" unless session[:authenticated]

    s3 = S3.new ENV["S3_ID"], ENV["S3_KEY"], ENV["S3_BUCKET"], ENV["S3_REGION"]
    @data = s3.get_all_objects
    erb :index
  end

  get "/o/:key" do
    redirect "/auth/google_oauth2" unless session[:authenticated]
    s3 = S3.new ENV["S3_ID"], ENV["S3_KEY"], ENV["S3_BUCKET"], ENV["S3_REGION"]
    @data = s3.get_object_data_by_key(params[:key], ENV["S3_LINK_TIMEOUT"])
    erb :show
  end

  get "/fail" do
    "You don't have access."
  end

  get '/auth/google_oauth2/callback' do
    auth = request.env['omniauth.auth']
    email = auth.info.email
    s3 = S3.new ENV["S3_ID"], ENV["S3_KEY"], ENV["S3_BUCKET"], ENV["S3_REGION"]
    if s3.can_read?(email)
      session[:authenticated] = true
      session[:info] = {email: auth.info.email, picture: auth.info.image, name: auth.info.name}
      redirect "/"
    else
      redirect "/fail"
    end

  end

  get "/logout" do
    session.clear
    "Logged out."
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end
