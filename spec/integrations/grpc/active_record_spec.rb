# frozen_string_literal: true

require "spec_helper"

describe "ActiveRecord connections release", :with_grpc_server, :rpc_command do
  include_context "rpc stub"

  let(:channel) { "ChatChannel" }

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
        expect(response.status).to eq :SUCCESS
        expect(response.transmissions.size).to eq 1
        expect(response.transmissions.first).to include({"name" => "ar_test"}.to_json)
      end

      connections = ActiveRecord::Base.connection_pool.connections.count(&:active?)
      expect(connections).to eq connections_was
    end
  end
end
