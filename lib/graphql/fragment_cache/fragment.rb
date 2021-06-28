# frozen_string_literal: true

require "graphql/fragment_cache/cache_key_builder"

module GraphQL
  module FragmentCache
    using Ext

    # Represents a single fragment to cache
    class Fragment
      NIL_IN_CACHE = Object.new

      class << self
        def read_multi(fragments)
          unless FragmentCache.cache_store.respond_to?(:read_multi)
            return fragments.map { |f| [f, f.read] }.to_h
          end

          fragments_to_cache_keys = fragments
            .map { |f| [f, f.cache_key] }.to_h

          cache_keys = fragments_to_cache_keys.values

          cache_keys_to_values = FragmentCache.cache_store.read_multi(*cache_keys)

          fetched_fragments_to_values = cache_keys_to_values
            .map { |key, val| [fragments_to_cache_keys.key(key), val] }
            .to_h

          fetched_fragments_to_values
        end
      end

      attr_reader :options, :path, :context

      def initialize(context, **options)
        @context = context
        @options = options
        @path = interpreter_context[:current_path]
      end

      def read(keep_in_context = false)
        return nil if context[:renew_cache] == true
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
