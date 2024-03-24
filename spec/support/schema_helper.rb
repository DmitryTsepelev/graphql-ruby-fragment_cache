# frozen_string_literal: true

module SchemaHelper
  def build_schema(&block)
    Class.new(GraphQL::Schema) do
      if GraphQL::FragmentCache::GraphRubyVersion.before_2_0?
        use GraphQL::Execution::Interpreter
        use GraphQL::Analysis::AST

        use GraphQL::Pagination::Connections
      end

      use GraphQL::FragmentCache

      instance_eval(&block)
    end
  end
end
