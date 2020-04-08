# frozen_string_literal: true

begin
  require "pry-byebug"
rescue LoadError
end

require "graphql-fragment_cache"

require "timecop"

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.example_status_persistence_file_path = "tmp/.rspec_status"

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.order = :random

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.formatter = :documentation
  config.color = true

  config.include SchemaHelper
  config.include_context "graphql"

  config.after do
    GraphQL::FragmentCache.cache_store.clear if GraphQL::FragmentCache.cache_store.respond_to?(:clear)
    Post.delete_all
    Timecop.return
  end
end
