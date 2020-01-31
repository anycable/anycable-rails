# frozen_string_literal: true

require "spec_helper"
require "action_controller/test_case"

describe "rack middleware support" do
  include_context "anycable:rpc:server"
  include_context "anycable:rpc:stub"

  include ActionDispatch::Integration::Runner
  include ActionDispatch::IntegrationTest::Behavior

  # Delegates to `Rails.application`.
  def app
    ::Rails.application
  end

  def new_session_cookie(data)
    post "/sessions", params: data
    expect(response.code).to eq "201"

    # Make sure we store session in cookies
    expect(response.cookies).to include("__anycable_dummy")

    response.cookies.map { |k, v| "#{k}=#{v}" }.join("&")
  end

  let(:params) { {} }
  let(:cookies) { new_session_cookie(params) }
  let(:headers) { {"cookie" => cookies} }
  let(:request) { AnyCable::ConnectionRequest.new(env: env) }

  let!(:user) { User.create!(name: "sean", secret: "joker") }

  context "session" do
    let(:params) { {data: {username: "sean", token: "joker"}} }

    it "is accessible in connection" do
      response = service.connect(request)
      expect(response.status).to eq :SUCCESS
      expect(JSON.parse(response.identifiers)).to include("current_user" => user.to_gid_param)
    end
  end

  context "warden" do
    let(:params) { {user_id: user.id} }

    it "is accessible in connection" do
      response = service.connect(request)
      expect(response.status).to eq :SUCCESS
      expect(JSON.parse(response.identifiers)).to include("current_user" => user.to_gid_param)
    end
  end
end
