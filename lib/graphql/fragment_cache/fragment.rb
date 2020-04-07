# frozen_string_literal: true

require "graphql/fragment_cache/cache_key_builder"

module GraphQL
  module FragmentCache
    # Represents a single fragment to cache
    class Fragment
      def initialize(context, **options)
        @context = context
        @options = options
        @path = context.namespace(:interpreter)[:current_path]
      end

      def cache_key
        @cache_key ||= CacheKeyBuilder.call(path: @path, query: @context.query, **@options)
      end

      def resolve(final_value)
        final_value.dig(*@path)
      end

      def expires_in
        @options[:expires_in]
      end
    end
  end
end
