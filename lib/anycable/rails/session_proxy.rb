# frozen_string_literal: true

module AnyCable
  module Rails
    # Wrap `request.session` to lazily load values provided
    # in the RPC call (set by the previous calls)
    class SessionProxy
      attr_reader :rack_session, :socket_session

      def initialize(rack_session, socket_session)
        @rack_session = rack_session
        @socket_session = JSON.parse(socket_session).with_indifferent_access
      end

      %i[has_key? [] []= fetch delete dig].each do |mid|
        class_eval <<~CODE, __FILE__, __LINE__ + 1
          def #{mid}(*args, **kwargs, &block)
            restore_key! args.first
            rack_session.#{mid}(*args, **kwargs, &block)
          end
        CODE
      end

      alias include? has_key?
      alias key? has_key?

      %i[update merge! to_hash].each do |mid|
        class_eval <<~CODE, __FILE__, __LINE__ + 1
          def #{mid}(*args, **kwargs, &block)
            restore!
            rack_session.#{mid}(*args, **kwargs, &block)
          end
        CODE
      end

      alias to_h to_hash

      def keys
        rack_session.keys + socket_session.keys
      end

      # Delegate both publuc and private methods to rack_session
      def respond_to_missing?(name, include_private = false)
        return false if name == :marshal_dump || name == :_dump
        rack_session.respond_to?(name, include_private) || super
      end

      def method_missing(method, *args, &block)
        if rack_session.respond_to?(method, true)
          rack_session.send(method, *args, &block)
        else
          super
        end
      end

      # This method is used by StimulusReflex to obtain `@by`
      def instance_variable_get(name)
        super || rack_session.instance_variable_get(name)
      end

      private

      def restore!
        socket_session.keys.each(&method(:restore_key!))
      end

      def restore_key!(key)
        return unless socket_session.key?(key)
        val = socket_session.delete(key)
        rack_session[key] =
          if val.is_a?(String)
            GlobalID::Locator.locate(val) || val
          else
            val
          end
      end
    end
  end
end
