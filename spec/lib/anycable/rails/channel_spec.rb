# frozen_string_literal: true

require "spec_helper"

supported = AnyCable.method(:broadcast).arity != 2

describe ActionCable::Channel::Base, skip: !supported do
  before { allow(AnyCable.broadcast_adapter).to receive(:raw_broadcast) }

  describe ".broadcast_to" do
    context "with to_others: true" do
      it "adds exclude_socket meta if current_socket_id is defined" do
        AnyCable::Rails.with_socket_id("456") do
          TestChannel.broadcast_to("test", {foo: "bar"}, to_others: true)
        end

        expect(AnyCable.broadcast_adapter).to have_received(:raw_broadcast).once
        expect(AnyCable.broadcast_adapter).to have_received(:raw_broadcast).with(
          {
            stream: "test:test",
            data: {foo: "bar"}.to_json,
            meta: {exclude_socket: "456"}
          }.to_json
        )
      end
    end

    context "when broadcasting_to_others is set" do
      specify do
        AnyCable::Rails.with_socket_id("456") do
          AnyCable::Rails.broadcasting_to_others do
            TestChannel.broadcast_to("test", {foo: "baz"})
          end
        end

        expect(AnyCable.broadcast_adapter).to have_received(:raw_broadcast).once
        expect(AnyCable.broadcast_adapter).to have_received(:raw_broadcast).with(
          {
            stream: "test:test",
            data: {foo: "baz"}.to_json,
            meta: {exclude_socket: "456"}
          }.to_json
        )
      end
    end
  end
end
