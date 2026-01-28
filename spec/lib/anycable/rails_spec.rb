# frozen_string_literal: true

require "spec_helper"

require "action_cable/subscription_adapter/inline"

describe AnyCable::Rails do
  describe ".extend_adapter!" do
    subject(:adapter) { ActionCable::SubscriptionAdapter::Inline.new(ActionCable.server) }

    before do
      described_class.extend_adapter!(adapter)
      allow(AnyCable).to receive(:broadcast)
    end

    specify do
      messages = []
      subject.subscribe "test", ->(msg) { messages << (msg.try(:data) || msg) }

      subject.broadcast "test", "hello"

      expect(AnyCable).to have_received(:broadcast).with("test", "hello")
      expect(messages).to eq(["hello"])
    end
  end

  describe ".signed_stream_name" do
    context "with streamable objects" do
      it "uses #to_gid_param and #to_param" do
        a = double("User")
        allow(a).to receive(:to_gid_param) { "gid://User/11" }

        b = double("Account")
        allow(b).to receive(:to_param) { "account_2024" }

        expect(AnyCable::Streams).to receive(:signed).with("gid://User/11:account_2024:new") { "<signed>" }

        expect(described_class.signed_stream_name([a, b, "new"])).to eq("<signed>")
      end
    end
  end
end
