# frozen_string_literal: true

require_relative "lib/anycable/rails/version"

Gem::Specification.new do |spec|
  spec.name = "anycable-rails-core"
  spec.version = AnyCable::Rails::VERSION
  spec.authors = ["palkan"]
  spec.email = ["dementiev.vm@gmail.com"]

  spec.summary = "AnyCable integration for Rails (w/o RPC dependencies)"
  spec.description = "AnyCable integration for Rails (w/o RPC dependencies)"
  spec.homepage = "http://github.com/anycable/anycable-rails"
  spec.license = "MIT"
  spec.metadata = {
    "bug_tracker_uri" => "http://github.com/anycable/anycable-rails/issues",
    "changelog_uri" => "https://github.com/anycable/anycable-rails/blob/master/CHANGELOG.md",
    "documentation_uri" => "https://docs.anycable.io/#/using_with_rails",
    "homepage_uri" => "https://anycable.io/",
    "source_code_uri" => "http://github.com/anycable/anycable-rails",
    "funding_uri" => "https://github.com/sponsors/anycable"
  }

  spec.files = Dir.glob("lib/**/*") + %w[README.md MIT-LICENSE CHANGELOG.md]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.0"

  spec.add_dependency "anycable-core", ">= 1.6.0-rc.1", "< 1.7.0"
  spec.add_dependency "actioncable", ">= 7.0", "< 9.0"
  spec.add_dependency "globalid"
end
