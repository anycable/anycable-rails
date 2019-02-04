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
end
