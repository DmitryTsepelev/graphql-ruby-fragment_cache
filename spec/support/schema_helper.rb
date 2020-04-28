# frozen_string_literal: true

module SchemaHelper
  def build_schema(&block)
    Class.new(GraphQL::Schema) do
      use GraphQL::Execution::Interpreter
      use GraphQL::Analysis::AST
      use GraphQL::Pagination::Connections
      use GraphQL::FragmentCache

      instance_eval(&block)
    end
  end
end
