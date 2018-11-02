# frozen_string_literal: true

require "spec_helper"

RSpec.describe Anycable::Compatibility::Anycable::InstanceVars do
  include_context "cop spec"

  it 'registers offense for instance var declaration in #subscribed' do
    inspect_source(<<-RUBY.strip_indent)
      class MyChannel < ApplicationCable::Channel
        def subscribed
          @instance_var
        end
      end
    RUBY

    expect(cop.offenses.size).to be(1)
    expect(cop.messages.first).to eq("Subscription instance variables are not supported in AnyCable")
  end

  it 'registers offense for instance var definition inside block in #subscribed' do
    inspect_source(<<-RUBY.strip_indent)
      class MyChannel < ApplicationCable::Channel
        def subscribed
          5.times { @instance_var = 1 }
        end
      end
    RUBY

    expect(cop.offenses.size).to be(1)
    expect(cop.messages.first).to eq("Subscription instance variables are not supported in AnyCable")
  end

  it 'registers offense for instance var definitions inside action' do
    inspect_source(<<-RUBY.strip_indent)
      class MyChannel < ApplicationCable::Channel
        def follow
          @instance_var = 1
        end
      end
    RUBY

    expect(cop.offenses.size).to be(1)
    expect(cop.messages.first).to eq("Subscription instance variables are not supported in AnyCable")
  end
end
