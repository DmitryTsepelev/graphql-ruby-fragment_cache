# frozen_string_literal: true

require_relative "base_type"
require_relative "user_type"

module TestTypes
  class PostType < BaseType
    field :id, ID, null: false
    field :title, String, null: false
    field :author, UserType, null: false
    field :cached_author, UserType, null: false

    def cached_author
      cache_fragment { object.author }
    end
  end
end
