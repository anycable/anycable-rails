# frozen_string_literal: true

require "spec_helper"
require "action_controller/test_case"

supported = AnyCable.method(:broadcast).arity != 2

describe "broadcast to others", skip: !supported do
  include ActionDispatch::Integration::Runner
  include ActionDispatch::IntegrationTest::Behavior

  # Delegates to `Rails.application`.
  def app
    ::Rails.application
  end

  before { allow(AnyCable.broadcast_adapter).to receive(:raw_broadcast) }

  it "adds exclude_socket meta if X-Socket-ID header is provided" do
    post "/broadcasts", params: {count: 1, to_others: true, disable_auto_batching: true}, headers: {"X-Socket-ID" => "134"}

    expect(AnyCable.broadcast_adapter).to have_received(:raw_broadcast).once
    expect(AnyCable.broadcast_adapter).to have_received(:raw_broadcast).with(
      {
        stream: "test",
        data: {count: 1}.to_json,
        meta: {exclude_socket: "134"}
      }.to_json
    )
  end

  it "doesn't add meta if header is missing" do
    post "/broadcasts", params: {count: 1, to_others: true, disable_auto_batching: true}

    expect(AnyCable.broadcast_adapter).to have_received(:raw_broadcast).once
    expect(AnyCable.broadcast_adapter).to have_received(:raw_broadcast).with(
      {
        stream: "test",
        data: {count: 1}.to_json
      }.to_json
    )
  end

  context "with custom header" do
    around do |example|
      was_value = AnyCable.config.socket_id_header
      AnyCable.config.socket_id_header = "X-My-Socket-ID"
      example.run
    ensure
      AnyCable.config.socket_id_header = was_value
    end

    specify do
      post "/broadcasts", params: {count: 1, to_others: true, disable_auto_batching: true}, headers: {"X-My-Socket-ID" => "134"}

      expect(AnyCable.broadcast_adapter).to have_received(:raw_broadcast).once
      expect(AnyCable.broadcast_adapter).to have_received(:raw_broadcast).with(
        {
          stream: "test",
          data: {count: 1}.to_json,
          meta: {exclude_socket: "134"}
        }.to_json
      )
    end
  end

  context "with background jobs" do
    if Rails::VERSION::MAJOR >= 7
      def queue_adapter_for_test
        ActiveJob::QueueAdapters::AsyncAdapter.new
      end
    else
      before do
        ActiveJob::Base.disable_test_adapter
      end
    end

    it "pass cable_socket_id to the job" do
      AnyCable::Rails.broadcasting_to_others(socket_id: "pagliacci") do
        BroadcastJob.perform_later("testo", {kind: "pizza"}, true)
      end

      # Wait for all jobs to be processed
      ActiveJob::Base.queue_adapter.shutdown

      expect(AnyCable.broadcast_adapter).to have_received(:raw_broadcast).once
      expect(AnyCable.broadcast_adapter).to have_received(:raw_broadcast).with(
        [{
          stream: "testo",
          data: {kind: "pizza"}.to_json,
          meta: {exclude_socket: "pagliacci"}
        }].to_json
      )
    end
  end
end
