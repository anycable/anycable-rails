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
        .to eq("<meta name=\"action-cable-url\" content=\"ws://local.test/cable?jid=test.jwt.token\" />")
    end

    it "when url already contains a query param" do
      expect(ActionCable.server.config).to receive(:url).and_return("ws://local.test/cable?secret=param")

      expect(action_cable_with_jwt_meta_tag(**payload))
        .to eq("<meta name=\"action-cable-url\" content=\"ws://local.test/cable?secret=param&amp;jid=test.jwt.token\" />")
    end
  end

  describe "#any_cable_jwt_meta_tag" do
    it "builds a metatag with a token" do
      expect(any_cable_jwt_meta_tag(**payload))
        .to eq("<meta name=\"any-cable-jwt\" content=\"test.jwt.token\" />")
    end
  end

  describe "#signed_stream_name" do
    it "builds a signed stream name via AnyCable::Streams.sign" do
      expect(AnyCable::Rails).to receive(:signed_stream_name).with("foo-bar").and_return("rab-oof")
      expect(AnyCable::Rails).to receive(:signed_stream_name).with([:a, 2]).and_return("b-3")

      expect(signed_stream_name("foo-bar")).to eq("rab-oof")
      expect(signed_stream_name([:a, 2])).to eq("b-3")
    end
  end
end
