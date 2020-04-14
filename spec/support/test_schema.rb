# frozen_string_literal: true

module Types
  class Base < GraphQL::Schema::Object
    include GraphQL::FragmentCache::Object
  end

  class User < Base
    graphql_name "UserType"

    field :id, ID, null: false
    field :name, String, null: false
  end

  class Post < Base
    graphql_name "PostType"

    field :id, ID, null: false
    field :title, String, null: false
    field :author, User, null: false
    field :cached_author, User, null: false

    def cached_author
      cache_fragment { object.author }
    end
  end

  class Query < Base
    graphql_name "QueryType"

    field :post, Post, null: true do
      argument :id, GraphQL::Types::ID, required: true
    end

    field :cached_post, Post, null: true do
      argument :id, GraphQL::Types::ID, required: true
    end

    def post(id:)
      ::Post.find(id)
    end

    def cached_post(id:)
      cache_fragment { ::Post.find(id) }
    end
  end
end

class TestSchema < GraphQL::Schema
  use GraphQL::Execution::Interpreter
  use GraphQL::Analysis::AST
  use GraphQL::FragmentCache

  query Types::Query
end
