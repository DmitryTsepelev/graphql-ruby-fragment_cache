# frozen_string_literal: true

def build_schema(query_type, context_key: nil)
  Class.new(GraphQL::Schema) do
    use GraphQL::Execution::Interpreter
    use GraphQL::Analysis::AST
    use GraphQL::FragmentCache, context_key: context_key

    query(query_type)
  end
end
