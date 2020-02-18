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
      expect(response).to be_success
      expect(JSON.parse(response.identifiers)).to include("current_user" => user.to_gid_param)
    end

    context "persistence" do
      include_context "rpc_command"

      let(:headers) { {"cookie" => cookies} }

      let(:channel_class) { "TestChannel" }
      let(:command) { "message" }
      let(:data) { {action: "tick"} }

      it "persists session after each command" do
        first_call = service.command(request)

        expect(first_call).to be_success
        expect(first_call.transmissions.size).to eq 1
        expect(first_call.transmissions.first).to include({"result" => 1}.to_json)
        expect(first_call.session).not_to be_nil

        first_session = first_call.session

        request.session = first_session

        second_call = service.command(request)

        expect(second_call).to be_success
        expect(second_call.transmissions.size).to eq 1
        expect(second_call.transmissions.first).to include({"result" => 2}.to_json)
        expect(second_call.session).not_to be_nil
        expect(second_call.session).not_to eq(first_session)
      end

      it "overrides yet unwrapped session values" do
        first_call = service.command(request)

        expect(first_call).to be_success
        expect(JSON.parse(first_call.session).fetch("tock")).to eq "tock"

        request.session = first_call.session
        data[:tick] = "tack"
        request.data = data.to_json

        second_call = service.command(request)
        expect(first_call).to be_success
        expect(JSON.parse(second_call.session).fetch("tock")).to eq "tack"
      end
    end
  end

  context "warden" do
    let(:params) { {user_id: user.id} }

    it "is accessible in connection" do
      response = service.connect(request)
      expect(response).to be_success
      expect(JSON.parse(response.identifiers)).to include("current_user" => user.to_gid_param)
    end
  end
end
