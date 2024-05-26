# frozen_string_literal: true

require "spec_helper"

describe AnyCable::Rails::Railtie do
  describe "anycable.warden_manager" do
    let(:initializer) { described_class.initializers.find { |init| init.name == "anycable.warden_manager" } }

    it "includes warden manager initializer" do
      expect(initializer).not_to be_nil
    end
  end
end
