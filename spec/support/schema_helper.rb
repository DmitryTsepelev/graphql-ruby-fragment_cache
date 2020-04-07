# frozen_string_literal: true

module SchemaHelper
  def build_schema(query_type, context_key: nil)
    Class.new(GraphQL::Schema) do
      use GraphQL::Execution::Interpreter
      use GraphQL::Analysis::AST
      use GraphQL::FragmentCache, context_key: context_key

      query(query_type)
    end
  end

  def build_key(schema, **options)
    Digest::SHA1.hexdigest(build_payload(schema, options).to_json)
  end

  def build_payload(schema, **options)
    query_cache_key = options[:query_cache_key] || {
      path_cache_key: options[:path_cache_key],
      selections_cache_key: options[:selections_cache_key]
    }

    {
      schema_cache_key: schema.schema_cache_key,
      query_cache_key: query_cache_key,
      context_cache_key: options[:context_cache_key]
    }
  end
end
