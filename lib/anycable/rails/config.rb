# frozen_string_literal: true

require "anycable/config"
# Make sure Rails extensions for Anyway Config are loaded
# See https://github.com/anycable/anycable-rails/issues/63
require "anyway/rails"

# Extend AnyCable configuration with:
# - `access_logs_disabled` (defaults to true) — whether to print Started/Finished logs
# - `persistent_session_enabled` (defaults to false) — whether to store session changes in the connection state
# - `embedded` (defaults to false) — whether to run RPC server inside a Rails server process
# - `http_rpc_mount_path` (defaults to nil) — path to mount HTTP RPC server
# - `batch_broadcasts` (defaults to false) — whether to batch broadcasts automatically for code wrapped with Rails executor
# - `jwt_param` (defaults to 'jid') — the name of the JWT authentication query paramter or header
# - `websocket_url` (defaults to nil) — the URL of AnyCable server WebSocket endpoint
AnyCable::Config.attr_config(
  access_logs_disabled: true,
  persistent_session_enabled: false,
  embedded: false,
  jwt_param: "jid",
  http_rpc_mount_path: nil,
  batch_broadcasts: false,
  socket_id_header: "X-Socket-ID",
  disable_rpc_pool_size_warning: false,
  websocket_url: nil,
)
AnyCable::Config.ignore_options :access_logs_disabled, :persistent_session_enabled
