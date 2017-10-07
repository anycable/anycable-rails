# frozen_string_literal: true

require 'spec_helper'
require 'generators/anycable/anycable_generator'

describe AnycableGenerator, type: :generator do
  destination File.expand_path("../../../tmp", __FILE__)

  let(:args) { [] }

  before do
    prepare_destination
    run_generator(args)
  end

  subject { file('bin/anycable') }

  it "creates script", :aggregate_failures do
    is_expected.to exist
    is_expected.to contain("Anycable.connection_factory = ActionCable.server.config.connection_class.call")
    is_expected.to contain("Rails.application.eager_load!")
    is_expected.to contain("Anycable::Server.start")
  end
end
