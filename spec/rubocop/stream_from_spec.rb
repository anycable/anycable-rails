# frozen_string_literal: true

require "cops_spec_helper"

describe RuboCop::Cop::AnyCable::StreamFrom do
  include_context "cop spec"

  it "registers offense for #stream_from with block" do
    inspect_source(<<~RUBY)
      class MyChannel < ApplicationCable::Channel
        def follow
          stream_from("all") {}
        end
      end
    RUBY

    expect(cop.offenses.size).to be(1)
    expect(cop.messages.first).to include("Custom stream callbacks are not supported in AnyCable")
  end

  it "registers offense for #stream_for with block" do
    inspect_source(<<~RUBY)
      class MyChannel < ApplicationCable::Channel
        def follow
          stream_for(user) {}
        end
      end
    RUBY

    expect(cop.offenses.size).to be(1)
    expect(cop.messages.first).to include("Custom stream callbacks are not supported in AnyCable")
  end

  it "registers offense for #stream_from with lambda" do
    inspect_source(<<~RUBY)
      class MyChannel < ApplicationCable::Channel
        def follow
          stream_from("all", -> {})
        end
      end
    RUBY

    expect(cop.offenses.size).to be(1)
    expect(cop.messages.first).to include("Custom stream callbacks are not supported in AnyCable")
  end

  it "registers offense for #stream_for with lambda" do
    inspect_source(<<~RUBY)
      class MyChannel < ApplicationCable::Channel
        def follow
          stream_for(user, -> {})
        end
      end
    RUBY

    expect(cop.offenses.size).to be(1)
    expect(cop.messages.first).to include("Custom stream callbacks are not supported in AnyCable")
  end

  it "registers offense for #stream_from with not JSON coder" do
    inspect_source(<<~RUBY)
      class MyChannel < ApplicationCable::Channel
        def follow
          stream_from("all", coder: SomeCoder)
        end
      end
    RUBY

    expect(cop.offenses.size).to be(1)
    expect(cop.messages.first).to include("Custom coders are not supported in AnyCable")
  end

  it "registers offense for #stream_for with not JSON coder" do
    inspect_source(<<~RUBY)
      class MyChannel < ApplicationCable::Channel
        def follow
          stream_for(user, coder: SomeCoder)
        end
      end
    RUBY

    expect(cop.offenses.size).to be(1)
    expect(cop.messages.first).to include("Custom coders are not supported in AnyCable")
  end

  it "does not register offense for #stream_from with JSON coder" do
    inspect_source(<<~RUBY)
      class MyChannel < ApplicationCable::Channel
        def follow
          stream_from("all", coder: ActiveSupport::JSON)
        end
      end
    RUBY

    expect(cop.offenses.size).to be(0)
  end
end
