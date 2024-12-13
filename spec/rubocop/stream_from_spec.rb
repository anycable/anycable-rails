# frozen_string_literal: true

require "cops_spec_helper"

describe RuboCop::Cop::AnyCable::StreamFrom do
  include_context "cop spec"

  it "registers offense for #stream_from with block" do
    expect_offense(<<~RUBY)
      class MyChannel < ApplicationCable::Channel
        def follow
          stream_from("all") {}
          ^^^^^^^^^^^^^^^^^^^^^ AnyCable/StreamFrom: Custom stream callbacks are not supported in AnyCable
        end
      end
    RUBY
  end

  it "registers offense for #stream_for with block" do
    expect_offense(<<~RUBY)
      class MyChannel < ApplicationCable::Channel
        def follow
          stream_for(user) {}
          ^^^^^^^^^^^^^^^^^^^ AnyCable/StreamFrom: Custom stream callbacks are not supported in AnyCable
        end
      end
    RUBY
  end

  it "registers offense for #stream_from with lambda" do
    expect_offense(<<~RUBY)
      class MyChannel < ApplicationCable::Channel
        def follow
          stream_from("all", -> {})
          ^^^^^^^^^^^^^^^^^^^^^^^^^ AnyCable/StreamFrom: Custom stream callbacks are not supported in AnyCable
        end
      end
    RUBY
  end

  it "registers offense for #stream_for with lambda" do
    expect_offense(<<~RUBY)
      class MyChannel < ApplicationCable::Channel
        def follow
          stream_for(user, -> {})
          ^^^^^^^^^^^^^^^^^^^^^^^ AnyCable/StreamFrom: Custom stream callbacks are not supported in AnyCable
        end
      end
    RUBY
  end

  it "registers offense for #stream_from with not JSON coder" do
    expect_offense(<<~RUBY)
      class MyChannel < ApplicationCable::Channel
        def follow
          stream_from("all", coder: SomeCoder)
                             ^^^^^^^^^^^^^^^^ AnyCable/StreamFrom: Custom coders are not supported in AnyCable
        end
      end
    RUBY
  end

  it "registers offense for #stream_for with not JSON coder" do
    expect_offense(<<~RUBY)
      class MyChannel < ApplicationCable::Channel
        def follow
          stream_for(user, coder: SomeCoder)
                           ^^^^^^^^^^^^^^^^ AnyCable/StreamFrom: Custom coders are not supported in AnyCable
        end
      end
    RUBY
  end

  it "does not register offense for #stream_from with JSON coder" do
    expect_no_offenses(<<~RUBY)
      class MyChannel < ApplicationCable::Channel
        def follow
          stream_from("all", coder: ActiveSupport::JSON)
        end
      end
    RUBY
  end
end
