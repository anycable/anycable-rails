# frozen_string_literal: true

require "cops_spec_helper"

describe RuboCop::Cop::AnyCable::PeriodicalTimers do
  include_context "cop spec"

  it "registers offense for #periodically call" do
    expect_offense(<<~RUBY)
      class MyChannel < ApplicationCable::Channel
        periodically(:do_something, every: 2.seconds)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ AnyCable/PeriodicalTimers: Periodical Timers are not supported in AnyCable
      end
    RUBY
  end

  it "registers offense for #periodically call explicit self" do
    expect_offense(<<~RUBY)
      class MyChannel < ApplicationCable::Channel
        self.periodically(:do_something, every: 2.seconds)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ AnyCable/PeriodicalTimers: Periodical Timers are not supported in AnyCable
      end
    RUBY
  end
end
