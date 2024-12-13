# frozen_string_literal: true

require_relative "lib/anycable/rails/version"

Gem::Specification.new do |spec|
  spec.name = "rubocop-anycable-rails"
  spec.version = AnyCable::Rails::VERSION
  spec.authors = ["palkan"]
  spec.email = ["dementiev.vm@gmail.com"]

  spec.summary = "RuboCop rules for AnyCable Rails"
  spec.description = "RuboCop rules for AnyCable Rails"
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

  spec.files = Dir.glob("lib/anycable/rails/rubocop/**/*") + %w[README.md MIT-LICENSE CHANGELOG.md lib/anycable/rails/version.rb lib/anycable/rails/rubocop.rb lib/anycable/rails/compatibility/rubocop.rb]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.7"

  spec.add_dependency "rubocop", ">= 1.0"
end
