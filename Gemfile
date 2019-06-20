source 'https://rubygems.org'

gemspec

gem 'sqlite3', '~> 1.3'

local_gemfile = "#{File.dirname(__FILE__)}/Gemfile.local"

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Lint/Eval
end
