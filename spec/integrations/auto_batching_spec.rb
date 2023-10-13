# frozen_string_literal: true

require "spec_helper"
require "action_controller/test_case"

describe "auto-batching", skip: !AnyCable.broadcast_adapter.respond_to?(:start_batching) do
  include ActionDispatch::Integration::Runner
  include ActionDispatch::IntegrationTest::Behavior

  # Delegates to `Rails.application`.
  def app
    ::Rails.application
  end

  before { allow(AnyCable.broadcast_adapter).to receive(:raw_broadcast) }

  it "delivers broadcasts in a single batch" do
    post "/broadcasts", params: {count: 3}
    expect(AnyCable.broadcast_adapter).to have_received(:raw_broadcast).once
  end

  context "when auto_batching disabled" do
    it "delivers broadcast individually" do
      post "/broadcasts", params: {count: 4, disable_auto_batching: true}
      expect(AnyCable.broadcast_adapter).to have_received(:raw_broadcast).exactly(4).times
    end
  end
end
