# frozen_string_literal: true

require "action_cable/connection"
require "anycable/rails/connections/serializable_identification"

ActionCable::Connection::Base.include(AnyCable::Rails::Connections::SerializableIdentification)
ActionCable::Connection::Base.prepend(Module.new do
  attr_reader :anycable_socket
  attr_accessor :anycable_request_builder

  # In AnyCable, we lazily populate env by passing it through the middleware chain,
  # so we access it via #request
  def env
    return super unless anycabled?

    request.env
  end

  def anycabled?
    @anycable_socket
  end

  private

  def request
    return super unless anycabled?

    @request ||= anycable_request_builder.build_rack_request(@env)
  end
end)
