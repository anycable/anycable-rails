# frozen_string_literal: true

require_relative "spec_helper"

describe Anycable::Rails::Compatibility::RemoteConnection do
  context "#disconnect" do
    let(:user) { User.new(name: "john", secret: "123") }
    let(:url) { "" }

    subject { ActionCable.server.remote_connections.where(current_user: user.to_gid_param, url: url) }

    it "throws CompatibilityError when called" do
      expect { subject.disconnect }.to raise_exception(
        Anycable::CompatibilityError,
        "Disconnecting remote clients is not supported in AnyCable!"
      )
    end
  end
end
