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

  let!(:user) { User.create!(name: "sean", secret: "joker") }

  context "session" do
    it "is accessible in connection" do
      post "/sessions", params: {data: {username: "sean", token: "joker"}}
      expect(response.code).to eq "201"

      # Make sure we store session in cookies
      expect(response.cookies).to include("__anycable_dummy")

      request = AnyCable::ConnectionRequest.new(
        env: AnyCable::Env.new(
          headers: {
            "Cookie" => response.cookies.map { |k, v| "#{k}=#{v}" }.join("&")
          }
        )
      )

      response = service.connect(request)

      expect(response.status).to eq :SUCCESS
    end
  end

  context "warden" do
    it "is accessible in connection" do
      post "/sessions", params: {user_id: user.id}
      expect(response.code).to eq "201"

      # Make sure we store session in cookies
      expect(response.cookies).to include("__anycable_dummy")

      request = AnyCable::ConnectionRequest.new(
        env: AnyCable::Env.new(
          headers: {
            "Cookie" => response.cookies.map { |k, v| "#{k}=#{v}" }.join("&")
          }
        )
      )

      response = service.connect(request)

      expect(response.status).to eq :SUCCESS
    end
  end
end
