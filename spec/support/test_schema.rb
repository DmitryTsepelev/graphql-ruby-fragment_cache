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

    field :meta, String, null: true

    def cached_author
      cache_fragment { object.author }
    end
  end

  class PostInput < GraphQL::Schema::InputObject
    argument :id, GraphQL::Types::ID, required: true
    argument :int_arg, Integer, required: true
  end

  class ComplexPostInput < GraphQL::Schema::InputObject
    argument :string_arg, String, required: true
    argument :input_with_id, PostInput, required: true
  end

  class Query < Base
    graphql_name "QueryType"

    field :post, Post, null: true do
      argument :id, GraphQL::Types::ID, required: true
    end

    field :cached_post, Post, null: true do
      argument :id, GraphQL::Types::ID, required: true
    end

    field :cached_post_by_input, Post, null: true do
      argument :input_with_id, PostInput, required: true
    end

    field :cached_post_by_complex_input, Post, null: true do
      argument :complex_post_input, ComplexPostInput, required: true
    end

    def post(id:)
      ::Post.find(id)
    end

    def cached_post(id:)
      cache_fragment { ::Post.find(id) }
    end

    def cached_post_by_input(input_with_id:)
      cache_fragment { ::Post.find(input_with_id.id) }
    end

    def cached_post_by_complex_input(complex_post_input:)
      cache_fragment { ::Post.find(complex_post_input.input_with_id.id) }
    end
  end
end

class TestSchema < GraphQL::Schema
  use GraphQL::Execution::Interpreter
  use GraphQL::Analysis::AST
  use GraphQL::FragmentCache

  query Types::Query
end
