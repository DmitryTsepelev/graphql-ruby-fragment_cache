# frozen_string_literal: true

module GraphQL
  module FragmentCache
    # Wraps resolver with cache method
    class CacheFragmentExtension < GraphQL::Schema::FieldExtension
      def initialize(options:, **_rest)
        @cache_options = options || {}
      end

      def resolve(object:, arguments:, **_options)
        cache_fragment_options = {
          schema_cache_key: @cache_options[:schema_cache_key],
          fragment_cache_namespace: @cache_options[:fragment_cache_namespace],
          query_cache_key: @cache_options[:query_cache_key]
        }

        object.cache_fragment(cache_fragment_options) { yield(object, arguments) }
      end
    end
  end
end
