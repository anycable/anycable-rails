source 'https://rubygems.org'

gemspec

local_gemfile = "#{File.dirname(__FILE__)}/Gemfile.local"

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Lint/Eval
else
  gem 'sqlite3', '~> 1.3'
  gem 'rails', '~> 6.0'
end
