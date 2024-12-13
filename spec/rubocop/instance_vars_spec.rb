# frozen_string_literal: true

require "cops_spec_helper"

describe RuboCop::Cop::AnyCable::InstanceVars do
  include_context "cop spec"

  it "registers offense for instance var declaration in #subscribed" do
    expect_offense(<<~RUBY)
      class MyChannel < ApplicationCable::Channel
        def subscribed
          @instance_var
          ^^^^^^^^^^^^^ AnyCable/InstanceVars: Channel instance variables are not supported in AnyCable. Use `state_attr_accessor` instead
        end
      end
    RUBY
  end

  it "registers offense for instance var definition inside block in #subscribed" do
    expect_offense(<<~RUBY)
      class MyChannel < ApplicationCable::Channel
        def subscribed
          5.times { @instance_var = 1 }
                    ^^^^^^^^^^^^^^^^^ AnyCable/InstanceVars: Channel instance variables are not supported in AnyCable. Use `state_attr_accessor` instead
        end
      end
    RUBY
  end

  it "registers offense for instance var definition inside condition in #subscribed" do
    expect_offense(<<~RUBY)
      class MyChannel < ApplicationCable::Channel
        def subscribed
          @instance_var = 1 if true
          ^^^^^^^^^^^^^^^^^ AnyCable/InstanceVars: Channel instance variables are not supported in AnyCable. Use `state_attr_accessor` instead
        end
      end
    RUBY
  end

  it "registers offense for instance var definition inside multiple assignments in #subscribed" do
    expect_offense(<<~RUBY)
      class MyChannel < ApplicationCable::Channel
        def subscribed
          a = b = @instance_var = 1
                  ^^^^^^^^^^^^^^^^^ AnyCable/InstanceVars: Channel instance variables are not supported in AnyCable. Use `state_attr_accessor` instead
        end
      end
    RUBY
  end

  it "registers offense for instance var definitions inside action" do
    expect_offense(<<~RUBY)
      class MyChannel < ApplicationCable::Channel
        def follow
          @instance_var = 1
          ^^^^^^^^^^^^^^^^^ AnyCable/InstanceVars: Channel instance variables are not supported in AnyCable. Use `state_attr_accessor` instead
        end
      end
    RUBY
  end
end
