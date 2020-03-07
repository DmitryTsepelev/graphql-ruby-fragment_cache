# frozen_string_literal: true

require "graphql"
require "graphql/fragment_cache"
require "helpers/test_schemas"

RSpec.configure do |config|
  config.order = :random

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.formatter = :documentation
  config.color = true
end
