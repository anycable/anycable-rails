source 'https://rubygems.org'

gemspec

gem "pry-byebug", platform: :mri

local_gemfile = "#{File.dirname(__FILE__)}/Gemfile.local"

eval_gemfile "gemfiles/rubocop.gemfile"

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Lint/Eval
else
  gem "anycable-core", github: "anycable/anycable"

  gem 'sqlite3', '~> 1.3'
  gem 'actioncable', '~> 6.0'
  gem 'activerecord'
end
