# frozen_string_literal: true

module GraphQL
  module FragmentCache
    # Extends key builder to use .expand_cache_key in Rails
    class CacheKeyBuilder
      def object_key(obj)
        return obj.graphql_cache_key if respond_to?(:graphql_cache_key)
        return obj.map { |item| object_key(item) } if obj.is_a?(Array)
        return object_key(obj.to_a) if obj.respond_to?(:to_a)

        ActiveSupport::Cache.expand_cache_key(obj)
      end
    end
  end
end
