# frozen_string_literal: true

require "spec_helper"

describe AnyCable::Rails do
  describe ".broadcast" do
    let(:user) { User.create!(name: "lua") }
    let(:user_gid) { user.to_gid_param }
    let(:account_class) do
      Struct.new(:id) do
        def to_param
          "account_#{id}"
        end
      end
    end

    before { allow(AnyCable.broadcast_adapter).to receive(:raw_broadcast) }

    it "convert objects to strings using GlobalId or #to_param" do
      account = account_class.new(2024)

      ActionCable.server.broadcast([user, account, :new], {test: 1})

      expect(AnyCable.broadcast_adapter).to have_received(:raw_broadcast).with(
        {
          stream: "#{user_gid}:account_2024:new",
          data: {test: 1}.to_json
        }.to_json
      )
    end

    context "with Action Cable testing" do
      let(:adapter) { ActionCable::SubscriptionAdapter::Test.new(ActionCable.server) }

      before { allow(ActionCable.server).to receive(:pubsub) { adapter } }

      specify do
        expect { ActionCable.server.broadcast(user, "hello") }
          .to have_broadcasted_to(user_gid)
      end
    end
  end
end
