# frozen_string_literal: true

require_relative "lib/anycable/rails/version"

Gem::Specification.new do |spec|
  spec.name = "anycable-rails"
  spec.version = AnyCable::Rails::VERSION
  spec.authors = ["palkan"]
  spec.email = ["dementiev.vm@gmail.com"]

  spec.summary = "Rails adapter for AnyCable"
  spec.description = "Rails adapter for AnyCable"
  spec.homepage = "http://github.com/anycable/anycable-rails"
  spec.license = "MIT"
  spec.metadata = {
    "bug_tracker_uri" => "http://github.com/anycable/anycable-rails/issues",
    "changelog_uri" => "https://github.com/anycable/anycable-rails/blob/master/CHANGELOG.md",
    "documentation_uri" => "https://docs.anycable.io/#/using_with_rails",
    "homepage_uri" => "https://anycable.io/",
    "source_code_uri" => "http://github.com/anycable/anycable-rails"
  }

  spec.files = Dir.glob("lib/**/*") + %w[README.md MIT-LICENSE CHANGELOG.md]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.6"

  spec.add_dependency "anycable", ">= 1.0.0"
  spec.add_dependency "actioncable", ">= 6"
  spec.add_dependency "globalid"

  spec.add_development_dependency "ammeter", "~> 1.1"
  spec.add_development_dependency "bundler", ">= 1.10"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec-rails", ">= 4.0.0"
  spec.add_development_dependency "rubocop", ">= 0.80"
  spec.add_development_dependency "warden"
end
