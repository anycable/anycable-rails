# frozen_string_literal: true

require "spec_helper"

describe AnyCable::Rails::ConnectionFactory do
  let(:env) { AnyCable::Env.new(url: "/cable", headers: {}) }
  let(:socket) { AnyCable::Socket.new(env: env) }

  context "default" do
    subject(:factory) { described_class.new }

    specify do
      connection = factory.call(socket)
      expect(connection.action_cable_connection).to be_an_instance_of(ApplicationCable::Connection)
    end
  end

  context "with routing" do
    let(:live_connection_class) do
      Class.new(ActionCable::Connection::Base)
    end

    let(:cable_connection_class) do
      Class.new(ActionCable::Connection::Base)
    end

    subject(:factory) do
      cable_class = cable_connection_class
      live_class = live_connection_class

      described_class.new do
        map "/cable" do
          cable_class
        end

        map "/admin/live" do
          live_class
        end
      end
    end

    specify do
      connection = factory.call(socket)
      expect(connection.action_cable_connection).to be_an_instance_of(cable_connection_class)

      env.url = "/admin/live?some=1"
      another_socket = AnyCable::Socket.new(env: env)

      connection = factory.call(another_socket)
      expect(connection.action_cable_connection).to be_an_instance_of(live_connection_class)
    end

    specify "no matching connections" do
      env.url = "/unknown"

      expect { factory.call(socket) }.to raise_error(/No connection class found matching \/unknown/i)
    end
  end
end
