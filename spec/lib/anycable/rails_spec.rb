# frozen_string_literal: true

require "spec_helper"

describe AnyCable::Rails do
  describe "#deserialize" do
    specify "primitive value", :aggregate_failures do
      expect(described_class.deserialize(1)).to eq 1
      expect(described_class.deserialize("1")).to eq "1"
      expect(described_class.deserialize(true)).to eq true
    end

    specify "hash value" do
      expect(described_class.deserialize({"a" => "b"})).to eq({"a" => "b"})
    end

    specify "global id" do
      user = User.create!(name: "Des")
      expect(described_class.deserialize(user.to_gid_param)).to eq user
    end

    context "with json" do
      specify "primitive value", :aggregate_failures do
        expect(described_class.deserialize("1", json: true)).to eq 1
        expect(described_class.deserialize('"1"', json: true)).to eq "1"
        expect(described_class.deserialize("true", json: true)).to eq true
      end
    end
  end

  describe "#serialize" do
    specify "primitive value" do
      expect(described_class.serialize(1)).to eq 1
      expect(described_class.serialize("1")).to eq "1"
      expect(described_class.serialize(true)).to eq true
    end

    specify "hash value" do
      expect(described_class.deserialize({"a" => "b"})).to eq({"a" => "b"})
    end

    specify "global id" do
      user = User.create!(name: "Des")
      expect(described_class.serialize(user)).to eq user.to_gid_param
    end

    context "with json" do
      specify "primitive value" do
        expect(described_class.serialize(1, json: true)).to eq "1"
        expect(described_class.serialize("1", json: true)).to eq '"1"'
        expect(described_class.serialize(true, json: true)).to eq "true"
      end

      specify "hash value" do
        expect(described_class.serialize({"a" => "b"}, json: true)).to eq({"a" => "b"}.to_json)
      end
    end
  end
end
