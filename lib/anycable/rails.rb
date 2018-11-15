# frozen_string_literal: true

require "anycable"
require "anycable/rails/version"
require "anycable/rails/config"

module AnyCable
  # Rails handler for AnyCable
  module Rails
    require "anycable/rails/railtie"
  end
end

# Warn if application has been already initialized.
# AnyCable should be loaded before initialization in order to work correctly.
if defined?(::Rails) && ::Rails.application && ::Rails.application.initialized?
  puts("\n**************************************************")
  puts(
    "⛔️  WARNING: AnyCable loaded after application initialization. Might not work correctly.\n"\
    "Please, make sure to remove `require: false` in your Gemfile or "\
    "require manually in `environment.rb` before `Rails.application.initialize!`"
  )
  puts("**************************************************\n\n")
end
