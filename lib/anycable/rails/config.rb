# frozen_string_literal: true

require "anycable/config"
# Make sure Rails extensions for Anyway Config are loaded
# See https://github.com/anycable/anycable-rails/issues/63
require "anyway/rails"

# Extend AnyCable configuration with:
# - `access_logs_disabled` (defaults to true) — whether to print Started/Finished logs
# - `persistent_session_enabled` (defaults to false) — whether to store session changes in the connection state
# - `embedded` (defaults to false) — whether to run RPC server inside a Rails server process
AnyCable::Config.attr_config(
  access_logs_disabled: true,
  persistent_session_enabled: false,
  embedded: false
)
AnyCable::Config.ignore_options :access_logs_disabled, :persistent_session_enabled
