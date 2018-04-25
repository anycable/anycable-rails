# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'anycable/rails/version'

Gem::Specification.new do |spec|
  spec.name          = "anycable-rails"
  spec.version       = Anycable::Rails::VERSION
  spec.authors       = ["palkan"]
  spec.email         = ["dementiev.vm@gmail.com"]

  spec.summary       = "Rails adapter for AnyCable"
  spec.description   = "Rails adapter for AnyCable"
  spec.homepage      = "http://github.com/anycable/anycable-rails"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", "5.2.0"
  spec.add_dependency "anycable", "~> 0.5.0"

  spec.add_development_dependency "bundler", "~> 1"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", ">= 3.4"
  spec.add_development_dependency "ammeter", "~> 1.1"
  spec.add_development_dependency "simplecov", ">= 0.3.8"
  spec.add_development_dependency "rubocop", ">= 0.50"
  spec.add_development_dependency "pry-byebug"
end
