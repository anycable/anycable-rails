# frozen_string_literal: true

require "base_spec_helper"

require File.expand_path("spec/dummy/config/environment", PROJECT_ROOT)

module ActionCable
  module Channel
    class Base
      # Make stream_from no-op
      def stream_from(*)
        streams
        # do nothing
      end

      def subscribe_to_channel
        run_callbacks :subscribe do
          subscribed
        end

        reject_subscription if subscription_rejected?
        ensure_confirmation_sent
      end

      def streams
        @_streams ||= []
      end
    end
  end
end

require "anycable/rails/compatibility"

describe "Compatibility" do
  describe "Channel" do
    class CompatibilityChannel < ActionCable::Channel::Base # rubocop:disable Lint/ConstantDefinitionInBlock
      def follow
      end
    end

    let(:socket) { instance_double("socket", subscribe: nil) }
    let(:connection) { instance_double("connection", identifiers: [], transmit: nil, socket: socket, logger: Logger.new(IO::NULL), anycabled?: false) }

    subject { CompatibilityChannel.new(connection, "channel_id") }

    describe "Channel#stream_from" do
      it "not throws exception when JSON coder is passed" do
        allow_any_instance_of(CompatibilityChannel).to receive(:follow) do |channel|
          channel.stream_from("all", coder: ActiveSupport::JSON)
        end

        expect { subject.follow }.not_to raise_exception
      end

      it "throws exception when not JSON coder is passed" do
        allow_any_instance_of(CompatibilityChannel).to receive(:follow) do |channel|
          channel.stream_from("all", coder: :some_coder)
        end

        expect { subject.follow }.to raise_exception(
          AnyCable::CompatibilityError,
          "Custom coders are not supported by AnyCable"
        )
      end

      it "throws exception when callback is passed" do
        allow_any_instance_of(CompatibilityChannel).to receive(:follow) do |channel|
          channel.stream_from("all", -> {})
        end

        expect { subject.follow }.to raise_exception(
          AnyCable::CompatibilityError,
          "Custom stream callbacks are not supported by AnyCable"
        )
      end

      it "throws exception when block is passed" do
        allow_any_instance_of(CompatibilityChannel).to receive(:follow) do |channel|
          channel.stream_from("all") {}
        end

        expect { subject.follow }.to raise_exception(
          AnyCable::CompatibilityError,
          "Custom stream callbacks are not supported by AnyCable"
        )
      end
    end

    describe "Channel#subscribe" do
      it "throws CompatibilityError when new instance variables were defined" do
        allow_any_instance_of(CompatibilityChannel).to receive(:subscribed) do |channel|
          channel.instance_variable_set(:@test, "test")
        end

        expect { subject.subscribe_to_channel }.to raise_exception(
          AnyCable::CompatibilityError,
          "Channel instance variables are not supported by AnyCable, but were set: @test"
        )
      end

      it "doesn't not throw when streams accessed" do
        allow_any_instance_of(CompatibilityChannel).to receive(:subscribed) do |channel|
          channel.stream_from "test"
        end

        expect { subject.subscribe_to_channel }.not_to raise_exception
      end
    end

    describe "Channel#perform_action" do
      it "throws CompatibilityError when new instance variables were defined" do
        allow_any_instance_of(CompatibilityChannel).to receive(:follow) do |channel|
          channel.instance_variable_set(:@test, "test")
        end

        expect { subject.perform_action("action" => "follow") }.to raise_exception(
          AnyCable::CompatibilityError,
          "Channel instance variables are not supported by AnyCable, but were set: @test"
        )
      end
    end

    describe "#periodically" do
      it "throws CompatibilityError when called" do
        expect do
          CompatibilityChannel.periodically(:do_something, every: 2.seconds)
        end.to raise_exception(
          AnyCable::CompatibilityError,
          "Periodical timers are not supported by AnyCable"
        )
      end
    end
  end
end
