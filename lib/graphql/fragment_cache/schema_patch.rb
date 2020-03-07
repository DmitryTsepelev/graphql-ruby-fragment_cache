# frozen_string_literal: true

require "digest/sha1"

module GraphQL
  module FragmentCache
    # Patches GraphQL::Schema to support fragment cache
    module SchemaPatch
      attr_reader :fragment_cache_store,
                  :fragment_cache_namespace,
                  :context_cache_key_resolver

      def fragment_cache_namespace=(value)
        @fragment_cache_namespace = value
      end

      def context_cache_key_resolver=(resolver)
        @context_cache_key_resolver = resolver
      end

      def schema_cache_key
        @schema_cache_key ||= Digest::SHA1.hexdigest(to_definition)
      end

      def configure_fragment_cache_store(store, options)
        @fragment_cache_store = StoreAdapters.build(store, options)
      end
    end
  end
end
