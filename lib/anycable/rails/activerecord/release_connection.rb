# frozen_string_literal: true
module Anycable
  module Rails
    module ActiveRecord
      # Release ActiveRecord connection after every call (if any)
      module ReleaseConnection
        def connect(*)
          wrap_release_connection { super }
        end

        def disconnect(*)
          wrap_release_connection { super }
        end

        def command(*)
          wrap_release_connection { super }
        end

        def wrap_release_connection
          res = yield
          ::ActiveRecord::Base.connection_pool.release_connection if
            ::ActiveRecord::Base.connection_pool.active_connection?
          res
        end
      end
    end
  end
end
