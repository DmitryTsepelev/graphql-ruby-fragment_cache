# frozen_string_literal: true

class AuthorLoader < GraphQL::Batch::Loader
  def perform(posts)
    posts.each { |post| fulfill(post, post.author) }
    posts.each { |post| fulfill(post, nil) unless fulfilled?(id) }
  end
end

module Types
  class Base < GraphQL::Schema::Object
    include GraphQL::FragmentCache::Object

    def current_user?
      context[:current_user]
    end

    def no_current_user?
      context[:current_user].nil?
    end
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
    field :cached_title, String, null: false, cache_fragment: true, method: :title
    field :author, User, null: false do
      argument :version, Integer, required: false
      argument :cached, Boolean, required: false
    end

    field :cached_author, User, null: false
    field :batched_cached_author, User, null: false
    field :cached_author_inside_batch, User, null: false

    field :meta, String, null: true

    def cached_author
      cache_fragment { object.author }
    end

    def batched_cached_author
      cache_fragment { AuthorLoader.load(object) }
    end

    def cached_author_inside_batch
      outer_path = context.namespace(:interpreter)[:current_path]

      AuthorLoader.load(object).then do |author|
        context.namespace(:interpreter)[:current_path] = outer_path
        cache_fragment(author, context: context)
      end
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

    def post(id:)
      ::Post.find(id)
    end

    def posts
      ::Post.all
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
  if GraphQL::FragmentCache.graphql_ruby_before_2_0?
    use GraphQL::Execution::Interpreter
    use GraphQL::Analysis::AST

    use GraphQL::Pagination::Connections
  end

  use GraphQL::Batch
  use GraphQL::FragmentCache

  query Types::Query
end
