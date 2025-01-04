require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

desc "Run specs without Rails"
RSpec::Core::RakeTask.new("spec:norails") do |task|
  task.exclude_pattern = "**/rails/**"
  task.verbose = false
end

task default: [:spec, "spec:norails"]
