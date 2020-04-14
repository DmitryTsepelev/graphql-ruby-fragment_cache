require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

desc "Run Ruby Next nextify"
task :nextify do
  sh "bundle exec ruby-next nextify ./lib --transpile-mode=rewrite -V"
end

desc "Run specs without Rails"
RSpec::Core::RakeTask.new("spec:norails") do |task|
  task.exclude_pattern = "**/rails/**"
  task.verbose = false
end

task default: [:spec, "spec:norails"]
