# frozen_string_literal: true

module SchemaHelper
  def build_schema(&block)
    Class.new(GraphQL::Schema) do
      use GraphQL::Execution::Interpreter
      use GraphQL::Analysis::AST
      use GraphQL::FragmentCache

      instance_eval(&block)
    end
  end

  def build_key(schema_cache_key:, **options)
    query_cache_key = options[:query_cache_key] || {
      path_cache_key: options[:path_cache_key],
      selections_cache_key: options[:selections_cache_key]
    }

    base_cache_key = Digest::SHA1.hexdigest(
      {
        schema_cache_key: schema_cache_key,
        query_cache_key: query_cache_key
      }.to_json
    )

    [base_cache_key, options[:cache_key]].compact.join("/")
  end
end
