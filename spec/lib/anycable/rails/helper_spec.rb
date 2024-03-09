# frozen_string_literal: true

describe AnyCable::Rails::Helper, type: :helper do
  let(:user) { User.create!(name: "Ann") }
  let(:payload) { {current_user: user} }

  before do
    allow(AnyCable::JWT).to receive(:encode).with(payload).and_return("test.jwt.token")
  end

  describe "#action_cable_with_jwt_meta_tag" do
    it "builds a metatag with a token in a query string" do
      expect(action_cable_with_jwt_meta_tag(**payload))
        .to eq("<meta name=\"action-cable-url\" content=\"ws://jwt.anycable.io/cable?jid=test.jwt.token\" />")
    end

    it "when url already contains a query param" do
      expect(ActionCable.server.config).to receive(:url).and_return("ws://jwt.anycable.io/cable?secret=param")

      expect(action_cable_with_jwt_meta_tag(**payload))
        .to eq("<meta name=\"action-cable-url\" content=\"ws://jwt.anycable.io/cable?secret=param&amp;jid=test.jwt.token\" />")
    end
  end

  describe "#any_cable_jwt_meta_tag" do
    it "builds a metatag with a token" do
      expect(any_cable_jwt_meta_tag(**payload))
        .to eq("<meta name=\"any-cable-jwt\" content=\"test.jwt.token\" />")
    end
  end
end
