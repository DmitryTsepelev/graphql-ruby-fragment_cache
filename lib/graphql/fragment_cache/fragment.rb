# frozen_string_literal: true

require "graphql/fragment_cache/cache_key_builder"

module GraphQL
  module FragmentCache
    # Represents a single fragment to cache
    class Fragment
      attr_reader :options, :path, :context

      def initialize(context, **options)
        @context = context
        @options = options
        @path = interpreter_context[:current_path]
      end

      NIL_IN_CACHE = Object.new

      def read
        FragmentCache.cache_store.read(cache_key).tap do |cached|
          return NIL_IN_CACHE if cached.nil? && FragmentCache.cache_store.exist?(cache_key)
        end
      end

      def persist
        value = final_value.dig(*path)
        FragmentCache.cache_store.write(cache_key, value, **options)
      end

      private

      def cache_key
        @cache_key ||= CacheKeyBuilder.call(path: path, query: context.query, **options)
      end

      def interpreter_context
        context.namespace(:interpreter)
      end

      def final_value
        @final_value ||= interpreter_context[:runtime].final_value
      end
    end
  end
end
