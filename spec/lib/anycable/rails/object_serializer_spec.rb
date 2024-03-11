# frozen_string_literal: true

require "spec_helper"

describe AnyCable::Rails::ObjectSerializer do
  describe "#deserialize" do
    specify "primitive value", :aggregate_failures do
      expect(described_class.deserialize(1)).to be_nil
      expect(described_class.deserialize("1")).to be_nil
      expect(described_class.deserialize(true)).to be_nil
    end

    specify "global id" do
      user = User.create!(name: "Des")
      expect(described_class.deserialize(user.to_gid_param)).to eq user
    end
  end

  describe "#serialize" do
    specify "primitive value" do
      expect(described_class.serialize(1)).to be_nil
      expect(described_class.serialize("1")).to be_nil
      expect(described_class.serialize(true)).to be_nil
    end

    specify "global id" do
      user = User.create!(name: "Des")
      expect(described_class.serialize(user)).to eq user.to_gid_param
    end
  end
end
