# frozen_string_literal: true

module Types
  class Base < GraphQL::Schema::Object
    include GraphQL::FragmentCache::Object
  end

  class User < Base
    graphql_name "UserType"

    field :id, ID, null: false
    field :name, String, null: false
    field :cached_avatar_url, String, null: true

    def cached_avatar_url
      cache_fragment { "http://example.com/img/users/#{object.id}" }
    end
  end

  class Activity < GraphQL::Schema::Union
  end

  class Post < Base
    graphql_name "PostType"

    field :id, ID, null: false
    field :title, String, null: false
    field :cached_title, String, null: false, cache_fragment: true, method: :title
    field :cached_avatar_url, String, null: true
    field :author, User, null: false
    field :cached_author, User, null: false
    field :related_activity, Activity, null: true

    field :meta, String, null: true

    def cached_author
      cache_fragment { object.author }
    end

    def cached_avatar_url
      cache_fragment { "http://example.com/img/posts/#{object.id}" }
    end

    def related_activity
      ::User.all.last
    end
  end

  class Activity < GraphQL::Schema::Union
    graphql_name "ActivityType"

    description "Represents chat message"

    possible_types Post, User

    def self.resolve_type(object, _context)
      Kernel.const_get("Types::#{object.class.name}")
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

    field :posts, [Post], null: false

    field :cached_post, Post, null: true do
      argument :id, GraphQL::Types::ID, required: true
    end

    field :cached_post_by_input, Post, null: true do
      argument :input_with_id, PostInput, required: true
    end

    field :cached_post_by_complex_input, Post, null: true do
      argument :complex_post_input, ComplexPostInput, required: true
    end

    field :feed, [Activity], null: false

    field :last_activity, Activity, null: false

    def post(id:)
      ::Post.find(id)
    end

    def posts
      ::Post.all
    end

    def feed
      ::Post.all + ::User.all
    end

    def last_activity
      ::Post.find(1)
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
  use GraphQL::Pagination::Connections
  use GraphQL::FragmentCache

  query Types::Query
end
