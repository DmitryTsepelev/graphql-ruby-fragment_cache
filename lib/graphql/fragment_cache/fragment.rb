# frozen_string_literal: true

require "graphql/fragment_cache/cache_key_builder"

module GraphQL
  module FragmentCache
    # Represents a single fragment to cache
    class Fragment
      attr_reader :options, :path, :context

      attr_accessor :resolved_value

      def initialize(context, **options)
        @context = context
        @options = options
        @path = interpreter_context[:current_path]
      end

      def read
        FragmentCache.cache_store.read(cache_key)
      end

      def persist
        # Connections are not available from the runtime object, so
        # we rely on Schema::Tracer to save it for us
        value = resolved_value || resolve_from_runtime
        FragmentCache.cache_store.write(cache_key, value, **options)
      end

      private

      def cache_key
        @cache_key ||= CacheKeyBuilder.call(path: path, query: context.query, **options)
      end

      def interpreter_context
        context.namespace(:interpreter)
      end

      def resolve_from_runtime
        final_value.dig(*path)
      end

      def final_value
        @final_value ||= interpreter_context[:runtime].final_value
      end
    end
  end
end
