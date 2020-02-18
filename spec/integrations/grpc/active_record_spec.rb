# frozen_string_literal: true

require "spec_helper"

describe "ActiveRecord connections release" do
  include_context "anycable:rpc:server"
  include_context "rpc_command"

  let(:channel_class) { "ChatChannel" }

  describe "#perform" do
    let!(:user) { User.create!(name: "ar_test") }
    let(:command) { "message" }
    let(:data) { {action: "find", id: user.id} }

    it "responds with result" do
      # warmup
      service.command(request)

      connections_was = ActiveRecord::Base.connection_pool.connections.count(&:active?)

      5.times do
        response = service.command(request)
        expect(response).to be_success
        expect(response.transmissions.size).to eq 1
        expect(response.transmissions.first).to include({"name" => "ar_test"}.to_json)
      end

      connections = ActiveRecord::Base.connection_pool.connections.count(&:active?)
      expect(connections).to eq connections_was
    end
  end
end
