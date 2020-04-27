# frozen_string_literal: true

# Add Warden middkeware to AnyCable stack to allow accessing
# Devise current user via `env["warden"].user`.
#
# See http://docs.anycable.io/#/ruby/authentication
AnyCable::Rails::Rack.middleware.use Warden::Manager do |config|
  Devise.warden_config = config
end
