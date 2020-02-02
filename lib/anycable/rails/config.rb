# frozen_string_literal: true

require "anycable/config"

# Extend AnyCable configuration with:
# - `access_logs_disabled` (defaults to true) — whether to print Started/Finished logs
# - `persistent_session_enabled` (defaults to false) — whether to store session changes in the connection state
AnyCable::Config.attr_config(
  access_logs_disabled: true,
  persistent_session_enabled: false
)
AnyCable::Config.ignore_options :access_logs_disabled, :persistent_session_enabled
