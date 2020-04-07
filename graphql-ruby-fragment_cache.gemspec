lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "graphql/fragment_cache/version"

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

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.5"

  spec.add_dependency "graphql", ">= 1.10.3"

  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "rspec", "~> 3.9"
  spec.add_development_dependency "rubocop", "0.79"
  spec.add_development_dependency "rubocop-md", "~> 0.3"
  spec.add_development_dependency "standard", "0.2.0"
  spec.add_development_dependency "timecop"
end
