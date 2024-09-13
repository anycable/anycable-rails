# frozen_string_literal: true

require "spec_helper"

describe "action cable testing compatibility", type: :channel do
  extend(Module.new do
    def channel_class
      TestChannel
    end

    def connection_class
      ApplicationCable::Connection
    end
  end)

  let(:user) { User.create!(name: "max", secret: "123") }

  context "channel tests" do
    before { stub_connection current_user: user }

    specify "subscription" do
      subscribe
      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_from("test")
    end

    specify "rejection" do
      user.update!(secret: "312")
      subscribe
      expect(subscription).to be_rejected
    end

    specify "perform" do
      subscribe

      perform :itick

      expect(transmissions.last).to eq("result" => 1)

      perform :itick

      expect(transmissions.last).to eq("result" => 2)
    end
  end

  context "connection tests" do
    specify "connect" do
      connect "/cable?token=123", session: {username: user.name}

      expect(connection.current_user).to eq user
    end

    specify "reject connection" do
      expect { connect }.to have_rejected_connection
    end

    specify "disconnect" do
      connect "/cable?token=123", session: {username: user.name}

      disconnect

      expect(ApplicationCable::Connection.events_log.last.fetch(:data)).to eq(name: "max", url: "http://test.host/cable?token=123")
    end

    specify "callbacks" do
      connect "/cable?token=123", session: {username: user.name}

      connection.handle_channel_command(
        {
          "identifier" => {channel: "ChatChannel"}.to_json,
          "command" => "subscribe"
        }
      )

      expect(socket.transmissions.last["type"]).to eq("confirm_subscription")
      expect(ApplicationCable::Connection.events_log.last[:source]).to eq "command"
    end
  end
end
