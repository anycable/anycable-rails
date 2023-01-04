# frozen_string_literal: true

require "spec_helper"

describe "subscription adapter" do
  subject(:adapter) { ActionCable.server.config.pubsub_adapter }

  specify { expect(adapter).to eq(ActionCable::SubscriptionAdapter::AnyCable) }

  context "with alias" do
    let(:config) { ActionCable.server.config.cable }

    around do |ex|
      old_adapter = config[:adapter]
      config[:adapter] = "anycable"
      ex.run
      config[:adapter] = old_adapter
    end

    specify { expect(adapter).to eq(ActionCable::SubscriptionAdapter::AnyCable) }
  end

  context "instance" do
    subject(:adapter) { ActionCable::SubscriptionAdapter::AnyCable.new }

    specify "#subscribe" do
      expect { adapter.subscribe("test", nil) }.to raise_error(NotImplementedError)
    end

    specify "#unsubscribe" do
      expect { adapter.unsubscribe("test", nil) }.to raise_error(NotImplementedError)
    end
  end
end
