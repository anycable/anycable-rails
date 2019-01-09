# frozen_string_literal: true
#

require 'anycable/config'

# Extend AnyCable configuration with
# `access_logs_disabled` options (defaults to true)
AnyCable::Config.attr_config access_logs_disabled: true
AnyCable::Config.ignore_options :access_logs_disabled
