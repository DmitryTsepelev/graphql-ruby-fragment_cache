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

          # Filter out all the cache_keys for fragments with renew_cache: true in their context
          cache_keys = fragments_to_cache_keys
            .reject { |k, _v| k.context[:renew_cache] == true }.values

          # If there are cache_keys look up values with read_multi otherwise return an empty hash
          cache_keys_to_values = if cache_keys.empty?
            {}
          else
            FragmentCache.cache_store.read_multi(*cache_keys)
          end

          begin
            fragments.map do |fragment|
              cache_lookup_event(
                cache_key: fragment.cache_key,
                operation_name: fragment.context.query.operation_name,
                path: fragment.path,
                cache_hit: cache_keys_to_values.key?(fragment.cache_key),
              )
            end
          rescue
            # Allow cache_lookup_event to fail when we do not have the data we need
          end

          # Fragmenst without values or with renew_cache: true in their context will have nil values like the read method
          fragments_to_cache_keys
            .map { |fragment, cache_key| [fragment, cache_keys_to_values[cache_key]] }.to_h
        end
      end

      attr_reader :options, :path, :context

      def initialize(context, **options)
        @context = context
        @keep_in_context = options.delete(:keep_in_context)
        @options = options
        @path = interpreter_context[:current_path]
      end

      def read
        return nil if context[:renew_cache] == true
        return read_from_context { value_from_cache } if @keep_in_context

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

      def cache_lookup_event(cache_key, operation_name, path, cache_hit)
        # This method can be implemented in your application
        # This provides a mechanism to monitor cache hits for a fragment
      end
    end
  end
end
