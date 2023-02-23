source 'https://rubygems.org'

gemspec

gem "debug", platform: :mri

local_gemfile = "#{File.dirname(__FILE__)}/Gemfile.local"

eval_gemfile "gemfiles/rubocop.gemfile"

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Lint/Eval
else
  gem 'actioncable', '~> 7.0'
  gem 'activerecord'
end

gem 'sqlite3', '~> 1.3'
