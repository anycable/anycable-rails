# frozen_string_literal: true

require "spec_helper"

describe AnyCable::Rails, type: :channel do
  extend(Module.new do
    def connection_class
      AnyCableTestConnection
    end
  end)

  before do
    stub_const("AnyCableTestConnection", Class.new(ActionCable::Connection::Base))
  end

  around do |ex|
    was_secret = AnyCable.config.streams_secret
    AnyCable.config.streams_secret = "do-not-tell-o"
    ex.run
  ensure
    AnyCable.config.streams_secret = was_secret
  end

  let(:legacy_conn) do
    req = ActionDispatch::TestRequest.create({"PATH_INFO" => "/cable"})
    conn = AnyCableTestConnection.allocate

    ws = double("websocket")
    allow(ws).to receive(:alive?) { true }
    allow(ws).to receive(:close)
    allow(conn).to receive(:websocket) { ws }

    conn.singleton_class.include(ActionCable::Connection::TestConnection)
    conn.send(:initialize, req)
    conn
  end

  before do
    next if defined?(socket)

    allow_any_instance_of(AnyCable::Rails::PubSubChannel).to receive(:stream_from)
  end

  let(:conn) { defined?(socket) ? connect : legacy_conn }

  let(:transmissions) do
    defined?(socket) ? socket.transmissions : conn.transmissions
  end

  let(:transmission) { transmissions.last }

  let(:user) { User.create!(name: "jack") }

  context "with cleartext stream name" do
    let(:identifier) do
      {
        channel: "$pubsub",
        stream_name: "test_1"
      }.to_json
    end

    it "with $pubsub channel and plain signed_stream" do
      conn.handle_channel_command({
        "command" => "subscribe",
        "identifier" => identifier
      })

      expect(transmission["type"]).to eq "reject_subscription"
      expect(transmission["identifier"]).to eq identifier
    end

    context "when public streams enabled" do
      it "confirms subscription" do
        expect(conn).to receive(:allow_public_streams?) { true }

        conn.handle_channel_command({
          "command" => "subscribe",
          "identifier" => identifier
        })

        expect(transmission["type"]).to eq "confirm_subscription"
        expect(transmission["identifier"]).to eq identifier
      end
    end
  end

  context "with signed streams" do
    let!(:identifier) do
      {
        channel: "$pubsub",
        signed_stream_name: AnyCable::Streams.signed("test_5")
      }.to_json
    end

    it "confirms subscription" do
      conn.handle_channel_command({
        "command" => "subscribe",
        "identifier" => identifier
      })

      expect(transmission["type"]).to eq "confirm_subscription"
      expect(transmission["identifier"]).to eq identifier
    end

    it "rejects if stream is not verified" do
      was_secret = AnyCable.config.streams_secret
      AnyCable.config.streams_secret = "another-secret"

      conn.handle_channel_command({
        "command" => "subscribe",
        "identifier" => identifier
      })

      expect(transmission["type"]).to eq "reject_subscription"
      expect(transmission["identifier"]).to eq identifier
    ensure
      AnyCable.config.streams_secret = was_secret
    end
  end
end
