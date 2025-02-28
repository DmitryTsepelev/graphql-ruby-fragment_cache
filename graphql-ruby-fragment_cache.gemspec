# frozen_string_literal: true

require_relative "lib/graphql/fragment_cache/version"

Gem::Specification.new do |spec|
  spec.name = "graphql-fragment_cache"
  spec.version = GraphQL::FragmentCache::VERSION
  spec.authors = ["DmitryTsepelev"]
  spec.email = ["dmitry.a.tsepelev@gmail.com"]

  spec.summary = "Fragment cache for graphql-ruby"
  spec.description = "Fragment cache for graphql-ruby"
  spec.homepage = "https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache"
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/CHANGELOG.md"

  spec.files = Dir.glob("lib/**/*") + Dir.glob("lib/.rbnext/**/*") + Dir.glob("bin/**/*") + %w[README.md LICENSE.txt CHANGELOG.md]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.1"

  spec.add_dependency "graphql", ">= 2.1.4"

  spec.add_development_dependency "combustion", "~> 1.1"
  spec.add_development_dependency "activerecord"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "rspec", "~> 3.9"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "unparser", "0.6.0"
  spec.add_development_dependency "graphql-batch"
  spec.add_development_dependency "parser"
end
