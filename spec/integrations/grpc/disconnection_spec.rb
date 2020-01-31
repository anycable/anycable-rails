# frozen_string_literal: true

require "spec_helper"

describe "disconnection" do
  include_context "anycable:rpc:server"
  include_context "rpc_command"

  let!(:user) { User.create!(name: "disco", secret: "123") }
  let(:url) { "http://example.io/cable?token=123" }
  let(:subscriptions) { [] }
  let(:headers) { {"Cookie" => "username=disco;"} }

  let(:request) do
    AnyCable::DisconnectRequest.new(
      identifiers: identifiers.to_json,
      subscriptions: subscriptions,
      env: env
    )
  end

  let(:log) { ApplicationCable::Connection.events_log }

  subject { service.disconnect(request) }

  describe "Connection#disconnect" do
    it "invokes #disconnect method with correct data" do
      expect { subject }.to change { log.size }.by(1)

      expect(log.last[:data]).to eq(name: "disco", url: "http://example.io/cable?token=123")
    end

    it "logs access message (closed)", log: :info do
      expect { subject }.to output(/Finished \"\/cable\?token=123\" \[AnyCable\].*\(Closed\)/).to_stdout_from_any_process
    end

    it "logs with tags when set", log: :info do
      request.cstate["__ltags__"] = ["u:john"].to_json
      expect { subject }.to output(/\[u:john\] Finished \"\/cable\?token=123\" \[AnyCable\].*\(Closed\)/).to_stdout_from_any_process
    end

    context "when access logs disabled" do
      around do |ex|
        was_disabled = AnyCable.config.access_logs_disabled
        AnyCable.config.access_logs_disabled = true
        ex.run
        AnyCable.config.access_logs_disabled = was_disabled
      end

      it "doesn't log access message", log: :info do
        expect { subject }.not_to output(/Finished \"\/cable\?token=123\" \[AnyCable\].*\(Closed\)/).to_stdout_from_any_process
      end
    end
  end

  describe "Channel#unsubscribed" do
    let(:subscriptions) { [channel_id] }
    let(:channel_class) { "ChatChannel" }

    it "invokes #unsubscribed for channel" do
      expect { subject }
        .to change { log.select { |entry| entry[:source] == channel_id }.size }
        .by(1)

      channel_logs = log.select { |entry| entry[:source] == channel_id }
      expect(channel_logs.last[:data]).to eq(user: "disco", type: "unsubscribed")
    end

    context "with multiple channels" do
      let(:channel2_id) { {channel: "TestChannel"}.to_json }
      let(:subscriptions) { [channel_id, channel2_id] }

      it "invokes #unsubscribed for each channel" do
        expect { subject }
          .to change { log.select { |entry| entry[:source] == channel_id }.size }
          .by(1)
          .and change { log.select { |entry| entry[:source] == channel2_id }.size }
          .by(1)

        channel_logs = log.select { |entry| entry[:source] == channel_id }
        expect(channel_logs.last[:data]).to eq(user: "disco", type: "unsubscribed")

        channel2_logs = log.select { |entry| entry[:source] == channel2_id }
        expect(channel2_logs.last[:data]).to eq(user: "disco", type: "unsubscribed")
      end
    end
  end
end
