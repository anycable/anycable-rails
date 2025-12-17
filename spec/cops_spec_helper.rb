# frozen_string_literal: true

require "base_spec_helper"

require "anycable/rails/compatibility/rubocop"

require "rubocop/rspec/support"

shared_context "cop spec" do
  include RuboCop::RSpec::ExpectOffense

  subject(:cop) { described_class.new }

  it "works with empty file" do
    expect_no_offenses("")
  end
end
