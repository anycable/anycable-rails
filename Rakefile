require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RuboCop::RakeTask.new

RSpec::Core::RakeTask.new(:spec)

desc "Run compatibility specs"
RSpec::Core::RakeTask.new("spec:compatibility") do |task|
  task.pattern = "spec/**/*_compatibility.rb"
  task.verbose = false
end

task default: %w[rubocop spec:compatibility spec]
