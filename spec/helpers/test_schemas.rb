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

def build_schema(query_type, context_key: nil)
  Class.new(GraphQL::Schema) do
    use GraphQL::Execution::Interpreter
    use GraphQL::Analysis::AST
    use GraphQL::FragmentCache, context_key: context_key

    query(query_type.is_a?(Proc) ? query_type.call : query_type)
  end
end
