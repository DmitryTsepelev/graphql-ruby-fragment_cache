# frozen_string_literal: true

module TestTypes
  class BaseType < GraphQL::Schema::Object
    include GraphQL::FragmentCache::Object
  end
end
