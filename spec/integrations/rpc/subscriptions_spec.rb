# frozen_string_literal: true

require "spec_helper"

describe "subscriptions" do
  include_context "rpc_command"

  let(:channel_class) { "TestChannel" }

  describe "#subscribe" do
    let(:command) { "subscribe" }
    let(:user) { User.create!(name: "john", secret: "123") }

    subject { handler.handle(:command, request) }

    context "reject subscription" do
      let(:user) { User.create!(name: "john", secret: "000") }

      it "responds with error and subscription rejection", :aggregate_failures do
        expect(subject).to be_failure
        expect(subject.streams).to eq []
        expect(subject.stop_streams).to eq true
        expect(subject.transmissions.first).to include("reject_subscription")
      end
    end

    context "successful subscription" do
      it "responds with success and subscription confirmation", :aggregate_failures do
        expect(subject).to be_success
        expect(subject.streams).to eq ["test"]
        expect(subject.stop_streams).to eq false
        expect(subject.transmissions.first).to include("confirm_subscription")
      end
    end

    context "unknown channel" do
      let(:channel_class) { "FakeChannel" }

      it "responds with error" do
        expect(subject).to be_error
        expect(subject.error_msg).to eq "Channel not found: FakeChannel"
      end
    end
  end

  describe "#unsubscribe" do
    let(:log) { ApplicationCable::Connection.events_log }

    let(:command) { "unsubscribe" }

    subject { handler.handle(:command, request) }

    it "responds with stop_all_streams" do
      expect(subject).to be_success
      expect(subject.stop_streams).to eq true
    end

    it "invokes #unsubscribed for channel" do
      expect { subject }
        .to change { log.select { |entry| entry[:source] == channel_id }.size }
        .by(1)

      channel_logs = log.select { |entry| entry[:source] == channel_id }
      expect(channel_logs.last[:data]).to eq(user: "john", type: "unsubscribed")
    end
  end
end
