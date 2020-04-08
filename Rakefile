require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

desc "Run specs without Rails"
RSpec::Core::RakeTask.new("spec:norails") do |task|
  task.exclude_pattern = "**/rails/**"
  task.verbose = false
end

task default: [:rubocop, :spec, "spec:norails"]
