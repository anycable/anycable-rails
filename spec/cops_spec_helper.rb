# frozen_string_literal: true

require "base_spec_helper"

require "anycable/rails/compatibility/rubocop"

require "rubocop/rspec/support"

shared_context "cop spec" do
  include RuboCop::RSpec::ExpectOffense

  # Make config explicit (Rails 6.0 specs failed due to #config method defined)
  let(:config) { RuboCop::Config.new({}, "#{Dir.pwd}/.rubocop.yml") }

  subject(:cop) { described_class.new }

  it "works with empty file" do
    inspect_source("")
    expect(cop.offenses.size).to be(0)
  end
end
