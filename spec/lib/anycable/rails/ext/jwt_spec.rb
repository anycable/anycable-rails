# frozen_string_literal: true

require "spec_helper"

describe AnyCable::Rails::Ext::JWT, type: :channel do
  extend(Module.new do
    def connection_class
      AnyCableTestConnection
    end
  end)

  before do
    stub_const("AnyCableTestConnection", Class.new(ActionCable::Connection::Base) do
      prepend AnyCable::Rails::Ext::JWT

      identified_by :user

      def handle_open
        connect
      rescue ActionCable::Connection::Authorization::UnauthorizedError
        close(reason: ActionCable::INTERNAL[:disconnect_reasons][:unauthorized], reconnect: false) if websocket&.alive?
      end

      def connect
        reject_unauthorized_connection unless anycable_jwt_present?

        identify_from_anycable_jwt!
      end
    end)
  end

  around do |ex|
    was_param = AnyCable.config.jwt_param
    AnyCable.config.jwt_param = "joken"
    ex.run
  ensure
    AnyCable.config.jwt_param = was_param
  end

  let(:user) { User.create!(name: "jack") }

  it "without a token" do
    expect { connect }.to have_rejected_connection
  end

  it "authenticates with a token in params" do
    token = AnyCable::JWT.encode({user: user})

    connect params: {joken: token}

    expect(connection.user).to eq user
  end

  it "authenticates with a token in headers" do
    token = AnyCable::JWT.encode({user: user})

    connect headers: {"x-joken" => token}

    expect(connection.user).to eq user
  end

  it "re-raise token decoding errors" do
    token = AnyCable::JWT.encode({user: user}).reverse

    expect { connect params: {joken: token} }.to raise_error(AnyCable::JWT::DecodeError)
  end

  it "rejects when signature is invalid" do
    token = AnyCable::JWT.encode({user: user}, secret_key: "another_key")

    expect { connect params: {joken: token} }.to have_rejected_connection
  end

  it "rejects with token_expired reason when expired" do
    token = AnyCable::JWT.encode({user: user}, expires_at: 1.minute.ago)

    req = ActionDispatch::TestRequest.create({"QUERY_STRING" => "joken=#{token}", "PATH_INFO" => "/cable"})
    conn = AnyCableTestConnection.allocate

    ws = double("websocket")
    allow(ws).to receive(:alive?) { true }
    expect(ws).to receive(:close)

    allow(conn).to receive(:websocket) { ws }

    conn.singleton_class.include(ActionCable::Connection::TestConnection)
    conn.send(:initialize, req)

    conn.handle_open

    expect(conn.transmissions.last["reason"]).to eq "token_expired"
  end
end
