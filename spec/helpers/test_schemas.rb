# frozen_string_literal: true

class User
  attr_reader :id, :name

  def initialize(id:, name:)
    @id = id
    @name = name
  end
end

class Post
  def self.find(id)
    author = User.new(id: id, name: "User ##{id}")
    new(id: id, title: "Post ##{id}", author: author)
  end

  attr_reader :id, :title, :author

  def initialize(id:, title:, author:)
    @id = id
    @title = title
    @author = author
  end
end

class UserType < GraphQL::Schema::Object
  field :id, ID, null: false
  field :name, String, null: false
end

class PostType < GraphQL::Schema::Object
  field :id, ID, null: false
  field :title, String, null: false
  field :author, UserType, null: false
  field :cached_author, UserType, null: false

  def cached_author
    cache_fragment { object.author }
  end
end

class QueryType < GraphQL::Schema::Object
  field :cached_post, PostType, null: true do
    argument :id, ID, required: true
  end

  field :post, PostType, null: true do
    argument :id, ID, required: true
  end

  def cached_post(id:)
    cache_fragment { post(id: id) }
  end

  def post(id:)
    Post.find(id)
  end
end

class GraphqSchema < GraphQL::Schema
  use GraphQL::Execution::Interpreter
  use GraphQL::Analysis::AST
  use GraphQL::FragmentCache

  query QueryType
end

class GraphqSchemaWithContextKey < GraphQL::Schema
  use GraphQL::Execution::Interpreter
  use GraphQL::Analysis::AST
  use GraphQL::FragmentCache, context_key: ->(context) { context[:current_user_id] }

  query QueryType
end
