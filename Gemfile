source 'https://rubygems.org'

gemspec name: "anycable-rails"

gem "debug", platform: :mri

if ENV["NEXT_ACTION_CABLE"] == "1"
  if File.directory?(File.join(__dir__, "..", "actioncable-next"))
    gem "actioncable-next", path: "../actioncable-next", require: false
  else
    gem "actioncable-next", require: false
  end
end

if File.directory?(File.join(__dir__, "../anycable-rb"))
  $stdout.puts "\n=== Using local AnyCable gem ===\n\n"
  gem "anycable", path: "../anycable-rb"
end

local_gemfile = "#{File.dirname(__FILE__)}/Gemfile.local"

eval_gemfile "gemfiles/rubocop.gemfile"

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Lint/Eval
else
  gem 'actioncable', '~> 8.0'
  gem 'activerecord'
  gem 'activejob'
end

gem 'sqlite3', '~> 2.0'
