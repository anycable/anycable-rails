# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "anycable/rails/version"

Gem::Specification.new do |spec|
  spec.name          = "anycable-rails"
  spec.version       = AnyCable::Rails::VERSION
  spec.authors       = ["palkan"]
  spec.email         = ["dementiev.vm@gmail.com"]

  spec.summary       = "Rails adapter for AnyCable"
  spec.description   = "Rails adapter for AnyCable"
  spec.homepage      = "http://github.com/anycable/anycable-rails"
  spec.license       = "MIT"

  spec.files         = `git ls-files README.md MIT-LICENSE CHANGELOG.md lib`.split
  spec.require_paths = ["lib"]

  spec.add_dependency "anycable", "~> 0.6.0"
  spec.add_dependency "rails", ">= 5"

  spec.add_development_dependency "bundler", ">= 1.10"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", ">= 3.4"
  spec.add_development_dependency "rubocop", "~> 0.60.0"
  spec.add_development_dependency "simplecov", ">= 0.3.8"
  spec.add_development_dependency "sqlite3", "~> 1.4.1"
end
