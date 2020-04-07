# frozen_string_literal: true

require "graphql"

require "graphql/fragment_cache/cache_fragment_extension"
require "graphql/fragment_cache/cache_instrumentation"
require "graphql/fragment_cache/fragment"
require "graphql/fragment_cache/object"
require "graphql/fragment_cache/schema_patch"
require "graphql/fragment_cache/memory_store"
require "graphql/fragment_cache/version"

module GraphQL
  # Plugin definition
  module FragmentCache
    class << self
      attr_reader :cache_store

      def use(schema_defn, options = {})
        verify_interpreter!(schema_defn)

        schema_defn.instrument(:query, CacheInstrumentation)
        schema_defn.extend(SchemaPatch)
      end

      def cache_store=(store)
        unless store.respond_to?(:read)
          raise ArgumentError, "Store must implement #read(key) method"
        end

        unless store.respond_to?(:write)
          raise ArgumentError, "Store must implement #write(key, val, **options) method"
        end

        @cache_store = store
      end

      private

      def verify_interpreter!(schema_defn)
        return if schema_defn.interpreter?

        raise StandardError,
          "GraphQL::Execution::Interpreter should be enabled for partial caching"
      end
    end

    self.cache_store = MemoryStore.new
  end
end
