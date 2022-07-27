require "spec_helper"
require './app'

ENV['RACK_ENV'] = 'test'

describe S3Server do
  include Rack::Test::Methods  #<---- you really need this mixin

  def app
    Sinatra::Application
  end

  let(:S3Server) { S3Server.new }


  context "GET to /" do
    let(:response) { get "/" }

    let "returns status 200 OK" do
      expect(response.status).to eq 200
    end

    it "non empty page returned" do
      expect(response.body).to_not be_nil
    end
  end

end
