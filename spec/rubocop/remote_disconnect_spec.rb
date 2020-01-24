# frozen_string_literal: true

require "cops_spec_helper"

describe RuboCop::Cop::AnyCable::RemoteDisconnect do
  include_context "cop spec"

  it "registers offense for remote disconnection attempt" do
    inspect_source(<<~RUBY)
      class MyChannel < ApplicationCable::Channel
        def subscribed
          ActionCable.server.remote_connections.where(current_user: user).disconnect
        end
      end
    RUBY

    expect(cop.offenses.size).to be(1)
    expect(cop.messages.first).to eq("Disconnecting remote clients is not supported in AnyCable")
  end
end
