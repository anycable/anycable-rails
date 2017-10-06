# frozen_string_literal: true

require "spec_helper"
require "bg_helper"

describe "disconnection", :rpc_command do
  include_context "rpc stub"

  let(:user) { User.new(name: 'disco', secret: '321') }
  let(:url) { 'http://example.io/cable?token=123' }
  let(:subscriptions) { [] }
  let(:headers) { { 'Cookie' => 'username=john;' } }

  let(:request) do
    Anycable::DisconnectRequest.new(
      identifiers: conn_id.to_json,
      subscriptions: subscriptions,
      path: url,
      headers: headers
    )
  end

  let(:log) { ApplicationCable::Connection.events_log }

  subject { service.disconnect(request) }

  describe "Connection#disconnect" do
    it "invokes #disconnect method with correct data" do
      expect { subject }.to change { log.size }.by(1)

      expect(log.last[:data]).to eq(name: 'disco', url: 'http://example.io/cable?token=123')
    end

    it "logs access message (closed)", log: :info do
      expect { subject }.to output(/Finished \"\/cable\?token=123\" \[Anycable\].*\(Closed\)/).to_stdout_from_any_process
    end

    context "when access logs disabled" do
      around do |ex|
        was_disabled = Anycable.config.access_logs_disabled
        Anycable.config.access_logs_disabled = true
        ex.run
        Anycable.config.access_logs_disabled = was_disabled
      end

      it "doesn't log access message", log: :info do
        expect { subject }.not_to output(/Finished \"\/cable\?token=123\" \[Anycable\].*\(Closed\)/).to_stdout_from_any_process
      end
    end
  end

  describe "Channel#unsubscribed" do
    let(:subscriptions) { [channel_id_json] }
    let(:channel) { 'ChatChannel' }

    it "invokes #unsubscribed for channel" do
      expect { subject }
        .to change { log.select { |entry| entry[:source] == channel_id_json }.size }
        .by(1)

      channel_logs = log.select { |entry| entry[:source] == channel_id_json }
      expect(channel_logs.last[:data]).to eq(user: 'disco', type: 'unsubscribed')
    end

    context "with multiple channels" do
      let(:subscriptions) { [channel_id_json, channel_id2_json] }
      let(:channel_id2_json) { { channel: "TestChannel" }.to_json }

      it "invokes #unsubscribed for each channel" do
        expect { subject }
          .to change { log.select { |entry| entry[:source] == channel_id_json }.size }
          .by(1)
          .and change { log.select { |entry| entry[:source] == channel_id2_json }.size }
          .by(1)

        channel_logs = log.select { |entry| entry[:source] == channel_id_json }
        expect(channel_logs.last[:data]).to eq(user: 'disco', type: 'unsubscribed')

        channel2_logs = log.select { |entry| entry[:source] == channel_id2_json }
        expect(channel2_logs.last[:data]).to eq(user: 'disco', type: 'unsubscribed')
      end
    end
  end
end
