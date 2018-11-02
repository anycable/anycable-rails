# frozen_string_literal: true

require "rubocop/rspec/support"

shared_context "cop spec" do
  include RuboCop::RSpec::ExpectOffense

  subject(:cop) { described_class.new }

  it "works with empty file" do
    inspect_source("")
    expect(cop.offenses.size).to be(0)
  end
end
