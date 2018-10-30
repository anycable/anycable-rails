require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RuboCop::RakeTask.new

task(:spec).clear

desc "Run specs"
RSpec::Core::RakeTask.new("spec") do |task|
  task.exclude_pattern = "spec/**/compatibility_spec.rb"
  task.verbose = false
end

desc "Run compatibility specs"
RSpec::Core::RakeTask.new("spec:compatibility") do |task|
  task.pattern = "spec/**/compatibility_spec.rb"
  task.verbose = false
end

task default: %w[rubocop spec:compatibility spec]
