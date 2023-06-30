# frozen_string_literal: true

require "spec_helper"
require "action_controller/test_case"

describe "rails integration" do
  context "no built-in ActionCable" do
    include ActionDispatch::Integration::Runner
    include ActionDispatch::IntegrationTest::Behavior

    # Delegates to `Rails.application`.
    def app
      ::Rails.application
    end

    it "responds with not found" do
      expect { get "/cable" }
        .to output(%r{No route matches \[GET\] "/cable"})
        .to_stdout_from_any_process
      expect(response.code).to eq "404"
    end
  end

  context "has embedded HTTP RPC server" do
    include ActionDispatch::Integration::Runner
    include ActionDispatch::IntegrationTest::Behavior

    # Delegates to `Rails.application`.
    def app
      ::Rails.application
    end

    specify do
      post "/_anycable/connect"
      expect(response.code).to eq "422"
      expect(response.body).to eq "Empty request body"
    end
  end

  it "assigns connection factory" do
    expect(AnyCable.connection_factory).to be_an_instance_of(AnyCable::Rails::ConnectionFactory)
  end

  context "integrates with error reporter", skip: (::Rails.version.to_f < 7.0) do
    include_context "rpc_command"

    let(:channel_class) { "TestChannel" }
    let(:command) { "message" }
    let(:data) { {action: "fail"} }

    it "notifies Rails reporter on exception" do
      response = handler.handle(:command, request)
      expect(response).to be_error

      last_reported_error, handled, context = TestErrorSubscriber.errors.last

      expect(last_reported_error).to be_a(NoMethodError)
      expect(handled).to be false
      expect(context[:method]).to eq(:command)
      expect(context[:payload]).to be_a(Hash)
    end
  end
end
