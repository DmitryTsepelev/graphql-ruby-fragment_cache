source "https://rubygems.org"

gem "pry-byebug", platform: :mri
# byebug requires "readline", which is a bundled gem on Ruby 3.5+/4.0 and must
# be declared explicitly so it loads under `bundle exec` (e.g. via Combustion).
gem "readline", platform: :mri

eval_gemfile "gemfiles/rubocop.gemfile"

# Specify your gem's dependencies in graphql-ruby-fragment_cache.gemspec
gemspec
