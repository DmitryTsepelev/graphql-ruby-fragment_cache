# frozen_string_literal: true

require "graphql/fragment_cache/cache_key_builder"

module GraphQL
  module FragmentCache
    using Ext

    # Represents a single fragment to cache
    class Fragment
      attr_reader :options, :path, :context

      def initialize(context, **options)
        @context = context
        @options = options
        @path = interpreter_context[:current_path]
      end

      NIL_IN_CACHE = Object.new

      def read(keep_in_context = false)
        return nil if context[:force_cache] == true
        return read_from_context { value_from_cache } if keep_in_context

        value_from_cache
      end

      def cache_key
        @cache_key ||= CacheKeyBuilder.call(path: path, query: context.query, **options)
      end

      def with_final_value?
        !final_value.nil?
      end

      def value
        final_value.dig(*path)
      end

      private

      def read_from_context
        if (loaded_value = context.loaded_fragments[cache_key])
          return loaded_value
        end

        yield.tap { |value| context.loaded_fragments[cache_key] = value }
      end

      def value_from_cache
        FragmentCache.cache_store.read(cache_key).tap do |cached|
          return NIL_IN_CACHE if cached.nil? && FragmentCache.cache_store.exist?(cache_key)
        end
      end

      def interpreter_context
        context.namespace(:interpreter)
      end

      def final_value
        @final_value ||= context.query.result["data"]
      end
    end
  end
end
