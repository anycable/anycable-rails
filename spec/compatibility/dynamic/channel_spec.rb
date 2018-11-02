# frozen_string_literal: true

require_relative "spec_helper"

describe Anycable::Rails::Compatibility::Channel do
  class CompatibilityChannel < ActionCable::Channel::Base
    def follow; end
  end

  let(:socket) { instance_double('socket', subscribe: nil) }
  let(:connection) do
    instance_double(
      'connection',
      identifiers: [],
      socket: socket,
      logger: Logger.new(IO::NULL)
    )
  end

  subject { CompatibilityChannel.new(connection, 'channel_id') }

  describe "#stream_from" do
    it "not throws exception when JSON coder is passed" do
      allow(subject).to receive(:follow) do
        subject.stream_from("all", coder: ActiveSupport::JSON)
      end

      expect { subject.perform_action('action' => 'follow') }.not_to raise_exception
    end

    it "throws exception when not JSON coder is passed" do
      allow(subject).to receive(:follow) do
        subject.stream_from("all", coder: :some_coder)
      end

      expect { subject.perform_action('action' => 'follow') }.to raise_exception(
        Anycable::CompatibilityError,
        "Custom coders are not supported in AnyCable!"
      )
    end

    it "throws exception when callback is passed" do
      allow(subject).to receive(:follow) do
        subject.stream_from("all", -> {})
      end

      expect { subject.perform_action('action' => 'follow') }.to raise_exception(
        Anycable::CompatibilityError,
        "Custom stream callbacks are not supported in AnyCable!"
      )
    end

    it "throws exception when block is passed" do
      allow(subject).to receive(:follow) do
        subject.stream_from("all") {}
      end

      expect { subject.perform_action('action' => 'follow') }.to raise_exception(
        Anycable::CompatibilityError,
        "Custom stream callbacks are not supported in AnyCable!"
      )
    end
  end

  describe "#subscribe" do
    it 'throws error when new instance variables were defined inside subscribed' do
      allow(subject).to receive(:subscribed) do
        subject.instance_variable_set(:@test, "test")
      end

      expect { subject.handle_subscribe }.to raise_exception(
        Anycable::CompatibilityError,
        "Channel instance variables are not supported in AnyCable!"
      )
    end

    it 'throws error when new instance variables were defined inside action' do
      allow(subject).to receive(:follow) do
        subject.instance_variable_set(:@test, "test")
      end

      expect { subject.perform_action('action' => 'follow') }.to raise_exception(
        Anycable::CompatibilityError,
        "Channel instance variables are not supported in AnyCable!"
      )
    end
  end

  describe "#periodically" do
    it 'throws CompatibilityError when called' do
      expect do
        CompatibilityChannel.periodically(:do_something, every: 2.seconds)
      end.to raise_exception(
        Anycable::CompatibilityError,
        "Periodical Timers are not supported in AnyCable!"
      )
    end
  end
end
