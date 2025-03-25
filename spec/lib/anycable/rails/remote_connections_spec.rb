# frozen_string_literal: true

require "spec_helper"

describe ActionCable::RemoteConnections do
  let!(:user) { User.create!(name: "matroskin") }

  before { allow(AnyCable.broadcast_adapter).to receive(:broadcast_command) }

  it "calls #broadcast_command" do
    ActionCable.server.disconnect(current_user: user, url: "anycable.io/cable")

    expect(AnyCable.broadcast_adapter).to have_received(:broadcast_command)
      .with(
        "disconnect",
        identifier: {current_user: user.to_gid_param, url: "anycable.io/cable"}.to_json,
        reconnect: true
      )
  end

  context "when AnyCable is disabled" do
    before do
      @old = ActionCable.server.config.cable[:adapter]
      ActionCable.server.config.cable[:adapter] = "test"
    end

    after do
      ActionCable.server.config.cable[:adapter] = @old
    end

    it "doesn't call #broadcast_command" do
      ActionCable.server.disconnect(current_user: user, url: "anycable.io/cable")

      expect(AnyCable.broadcast_adapter).not_to have_received(:broadcast_command)
    end
  end
end
