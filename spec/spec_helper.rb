# frozen_string_literal: true

require "graphql"
require "graphql/fragment_cache"

require "helpers/build_key"
require "helpers/build_schema"
require "helpers/check_used_key"

require "helpers/test_models/user"
require "helpers/test_models/post"

require "helpers/test_types/base_type"
require "helpers/test_types/user_type"
require "helpers/test_types/post_type"

RSpec.configure do |config|
  config.order = :random

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.formatter = :documentation
  config.color = true
end
