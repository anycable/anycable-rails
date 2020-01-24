# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "anycable/rails/version"

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

  spec.required_ruby_version = ">= 2.4"

  spec.add_dependency "anycable", "~> 0.6.0"
  spec.add_dependency "rails", ">= 5"

  spec.add_development_dependency "ammeter", "~> 1.1"
  spec.add_development_dependency "bundler", ">= 1.10"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", ">= 3.4"
  spec.add_development_dependency "rubocop-md", "~> 0.3"
  spec.add_development_dependency "simplecov", ">= 0.3.8"
  spec.add_development_dependency "standard", "~> 0.1.7"
end
