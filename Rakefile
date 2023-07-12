# frozen_string_literal: true

require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new

  RuboCop::RakeTask.new("rubocop:md") do |task|
    task.options << %w[-c .rubocop-md.yml]
  end
rescue LoadError
  task(:rubocop) {}
  task("rubocop:md") {}
end

desc "Run compatibility specs"
RSpec::Core::RakeTask.new("spec:compatibility") do |task|
  task.pattern = "spec/**/*_compatibility.rb"
  task.verbose = false
end

task default: %w[rubocop rubocop:md spec:compatibility spec]
