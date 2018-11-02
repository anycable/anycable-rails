# frozen_string_literal: true

require "spec_helper"

RSpec.describe Anycable::Compatibility::Anycable::InstanceVars do
  include_context "cop spec"

  it "registers offense for instance vars in the middle of #subscribed" do
    inspect_source(<<-RUBY.strip_indent)
      class MyChannel < ApplicationCable::Channel
        def subscribed
          method_call
          @instance_var = 'something'
          stream_from @instance_var
        end
      end
    RUBY

    expect(cop.offenses.size).to be(1)
    expect(cop.messages.first).to eq("Subscription instance variables are not supported in AnyCable")
  end

  it "registers offense for instance vars in the beginning of #subscribed" do
    inspect_source(<<-RUBY.strip_indent)
      class MyChannel < ApplicationCable::Channel
        def subscribed
          @instance_var = 'something'
          stream_from @instance_var
        end
      end
    RUBY

    expect(cop.offenses.size).to be(1)
    expect(cop.messages.first).to eq("Subscription instance variables are not supported in AnyCable")
  end

  it "registers offense for instance var definitions in #subscribed" do
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

  it "registers offense for instance var definitions inside block in #subscribed" do
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
end
