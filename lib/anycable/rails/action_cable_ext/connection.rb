# frozen_string_literal: true

require "action_cable"
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

# Backport command callbacks: https://github.com/rails/rails/pull/44696
unless ActionCable::Connection::Base.respond_to?(:before_command)
  ActionCable::Connection::Base.include ActiveSupport::Callbacks
  ActionCable::Connection::Base.define_callbacks :command
  ActionCable::Connection::Base.extend(Module.new do
    def before_command(*methods, &block)
      set_callback(:command, :before, *methods, &block)
    end

    def after_command(*methods, &block)
      set_callback(:command, :after, *methods, &block)
    end

    def around_command(*methods, &block)
      set_callback(:command, :around, *methods, &block)
    end
  end)

  ActionCable::Connection::Base.prepend(Module.new do
    def dispatch_websocket_message(*)
      return super unless websocket.alive?

      run_callbacks(:command) { super }
    end
  end)
end
