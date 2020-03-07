# frozen_string_literal: true

require "graphql/fragment_cache/cache_instrumentation"
require "graphql/fragment_cache/fragment"
require "graphql/fragment_cache/object"
require "graphql/fragment_cache/schema_patch"
require "graphql/fragment_cache/store_adapters"
require "graphql/fragment_cache/version"

module GraphQL
  # Plugin definition
  module FragmentCache
    DEFAULT_CACHE_NAMESPACE = "graphql:fragment_cache"

    class << self
      def use(schema_defn, options = {})
        verify_interpreter(schema_defn)

        schema_defn.instrument(:query, CacheInstrumentation)
        schema_defn.singleton_class.prepend(SchemaPatch)

        schema_defn.fragment_cache_namespace = options[:namespace] || DEFAULT_CACHE_NAMESPACE
        schema_defn.context_cache_key_resolver = options[:context_key] # TODO: symbol or lambda

        store = options[:store] || :memory
        schema_defn.configure_fragment_cache_store(store, options)

        GraphQL::Schema::Object.include(Object)
      end

      private

      def verify_interpreter(schema_defn)
        return if schema_defn.interpreter?

        raise StandardError,
              "GraphQL::Execution::Interpreter should be enabled for partial caching"
      end
    end
  end
end
