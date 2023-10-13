# frozen_string_literal: true

require "anycable"
require "anycable/rails/version"
require "anycable/rails/config"
require "anycable/rails/rack"

require "globalid"
require "active_support/core_ext/module/attribute_accessors_per_thread"

module AnyCable
  # Rails handler for AnyCable
  module Rails
    require "anycable/rails/railtie"

    ADAPTER_ALIASES = %w[any_cable anycable].freeze

    thread_mattr_accessor :current_socket_id
    thread_mattr_accessor :current_broadcast_options

    class << self
      def enabled?
        adapter = ::ActionCable.server.config.cable&.fetch("adapter", nil)
        compatible_adapter?(adapter)
      end

      def compatible_adapter?(adapter)
        ADAPTER_ALIASES.include?(adapter)
      end

      def with_socket_id(socket_id)
        old_socket_id, self.current_socket_id = current_socket_id, socket_id
        yield
      ensure
        self.current_socket_id = old_socket_id
      end

      def with_broadcast_options(**options)
        old_options = current_broadcast_options
        self.current_broadcast_options = options.reverse_merge(old_options || {})
        yield
      ensure
        self.current_broadcast_options = old_options
      end

      def broadcasting_to_others(socket_id: nil, &block)
        if socket_id
          with_socket_id(socket_id) { with_broadcast_options(to_others: true, &block) }
        else
          with_broadcast_options(to_others: true, &block)
        end
      end

      # Serialize connection/channel state variable to string
      # using GlobalID where possible or JSON (if json: true)
      def serialize(obj, json: false)
        obj.try(:to_gid_param) || (json ? obj.to_json : obj)
      end

      # Deserialize previously serialized value from string to
      # Ruby object.
      # If the resulting object is a Hash, make it indifferent
      def deserialize(str, json: false)
        str.yield_self do |val|
          next val unless val.is_a?(String)

          gval = GlobalID::Locator.locate(val)
          return gval if gval

          next val unless json

          JSON.parse(val)
        end.yield_self do |val|
          next val.with_indifferent_access if val.is_a?(Hash)
          val
        end
      end

      module Extension
        def broadcast(...)
          super
          ::AnyCable.broadcast(...)
        end
      end

      def extend_adapter!(adapter)
        adapter.extend(Extension)
      end
    end
  end
end

# Warn if application has been already initialized.
# AnyCable should be loaded before initialization in order to work correctly.
if defined?(::Rails) && ::Rails.application && ::Rails.application.initialized?
  puts("\n**************************************************")
  puts(
    "⛔️  WARNING: AnyCable loaded after application initialization. Might not work correctly.\n" \
    "Please, make sure to remove `require: false` in your Gemfile or " \
    "require manually in `environment.rb` before `Rails.application.initialize!`"
  )
  puts("**************************************************\n\n")
end
