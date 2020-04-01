source 'https://rubygems.org'

gemspec

gem "pry-byebug", platform: :mri

local_gemfile = "#{File.dirname(__FILE__)}/Gemfile.local"

eval_gemfile "gemfiles/rubocop.gemfile"

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Lint/Eval
else
  # TEMP: while 1.0 in development
  gem "anycable", github: "anycable/anycable", branch: "1.0-dev"

  gem 'sqlite3', '~> 1.3'
  gem 'rails', '~> 6.0'
end
