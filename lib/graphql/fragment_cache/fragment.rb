# frozen_string_literal: true

require "graphql/fragment_cache/cache_key_builder"

module GraphQL
  module FragmentCache
    # Represents a single fragment to cache
    class Fragment
      attr_reader :options, :path, :context, :raw_connection

      attr_writer :raw_connection

      def initialize(context, **options)
        @context = context
        @options = options
        @path = context.namespace(:interpreter)[:current_path]
      end

      def read
        FragmentCache.cache_store.read(cache_key)
      end

      def persist(final_value)
        value = raw_connection || resolve(final_value)
        FragmentCache.cache_store.write(cache_key, value, **options)
      end

      private

      def cache_key
        @cache_key ||= CacheKeyBuilder.call(path: path, query: context.query, **options)
      end

      def resolve(final_value)
        final_value.dig(*path)
      end
    end
  end
end
