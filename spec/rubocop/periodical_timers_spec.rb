# frozen_string_literal: true

require "cops_spec_helper"

describe RuboCop::Cop::AnyCable::PeriodicalTimers do
  include_context "cop spec"

  it "registers offense for #periodically call" do
    inspect_source(<<-RUBY.strip_indent)
      class MyChannel < ApplicationCable::Channel
        periodically(:do_something, every: 2.seconds)
      end
    RUBY

    expect(cop.offenses.size).to be(1)
    expect(cop.messages.first).to eq("Periodical Timers are not supported in AnyCable")
  end

  it "registers offense for #periodically call explicit self" do
    inspect_source(<<-RUBY.strip_indent)
      class MyChannel < ApplicationCable::Channel
        self.periodically(:do_something, every: 2.seconds)
      end
    RUBY

    expect(cop.offenses.size).to be(1)
    expect(cop.messages.first).to eq("Periodical Timers are not supported in AnyCable")
  end
end
