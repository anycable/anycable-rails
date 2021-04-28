# frozen_string_literal: true

shared_context "rpc_command" do
  include_context "anycable:rpc:command"

  let(:user) { User.create!(name: "john", secret: "123") }
  let(:url) { "" }
  let(:identifiers) { {current_user: user.to_gid_param, url: url} }

  let(:channel_params) { {} }
  let(:channel_identifier) { {channel: channel_class}.merge(channel_params) }
  let(:channel_id) { channel_identifier.to_json }

  let(:handler) { AnyCable::RPC::Handler.new }
end
