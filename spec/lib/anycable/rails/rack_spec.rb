# frozen_string_literal: true

require "spec_helper"

describe AnyCable::Rails::Rack do
  it "uses Session middleware" do
    expect(described_class.default_middleware_stack.middlewares).to include(ActionDispatch::Session::CookieStore)
  end

  it "acts as rack application" do
    env = {}
    described_class.app.call(env)
    expect(env["rack.session"]).to be_a ActionDispatch::Request::Session
  end
end
