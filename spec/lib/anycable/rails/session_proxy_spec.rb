# frozen_string_literal: true

require "spec_helper"

describe AnyCable::Rails::Connections::SessionProxy do
  let(:rack_session) { { "existing_key" => 1 }.with_indifferent_access }
  let(:persisted_session) { { "restored_key" => 2 }.to_json }
  subject(:proxy) { described_class.new(rack_session, persisted_session) }

  it "includes restored values when enumerating the session" do
    expect(proxy.each.to_a).to contain_exactly(
      ["existing_key", 1],
      ["restored_key", 2]
    )
  end

  it "uses the restored session for Enumerable operations" do
    expect(proxy.map { |key, value| [key, value * 2] }).to contain_exactly(
      ["existing_key", 2],
      ["restored_key", 4]
    )
  end
end
