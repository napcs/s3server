module S3Server
  VERSION = "0.5.1"

  require 'sinatra/base'
  require 'aws-sdk'
  require 'dotenv/load'
  require 'omniauth-oauth2'
  require 'omniauth-google-oauth2'
  require "sinatra/reloader"

  require 'pp'
  require_relative "lib/s3"
  require_relative "lib/helpers"

  class Server < Sinatra::Base
    configure :development do
      register Sinatra::Reloader
    end

    use Rack::Session::Cookie, key: "S3Server", path: "/", secret: ENV['S3SERVER_SECRET_KEY']

    use OmniAuth::Builder do
      provider :google_oauth2, ENV["GOOGLE_ID"], ENV['GOOGLE_SECRET']
    end

    get "/login" do
      auth = Rack::Auth::Basic::Request.new(request.env)

      if auth.provided? and auth.basic? and auth.credentials and can_access_bucket_with_password?(auth.credentials.first, auth.credentials.last)
        session[:authenticated] = true
        session[:info] = {name: auth.credentials.first}
        redirect "/"
      else
        headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
        halt 401, "Not authorized\n"
      end
    end


    get "/" do
      login_check
      s3 = get_s3_connection
      @data = s3.get_all_objects
      erb :index
    end

    get "/o/*" do
      login_check
      key = params[:splat].first
      s3 = get_s3_connection
      @data = s3.get_object_data_by_key(key, ENV["S3_LINK_TIMEOUT"])
      erb :show
    end

    get "/fail" do
      "You don't have access."
    end

    get '/auth/google_oauth2/callback' do
      auth = request.env['omniauth.auth']
      email = auth.info.email
      if can_access_bucket?(email)
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

    private

    def login_check
      unless ENV["S3SERVER_LOGIN"] == "none"
        return if session[:authenticated]
        if ENV["S3SERVER_LOGIN"] == "google"
          redirect "/auth/google_oauth2"
        else
          redirect "/login"
        end
      end
    end

    def get_s3_connection
      S3.new ENV["S3_ID"], ENV["S3_KEY"], ENV["S3_BUCKET"], ENV["S3_REGION"], ENV["S3_ENDPOINT"]
    end

    def can_access_bucket?(email)
      s3 = get_s3_connection
      s3.can_read?(email)
    end

    def can_access_bucket_with_password?(email, password)
      s3 = get_s3_connection
      s3.can_read_with_password?(email, password)
    end

  end
end
