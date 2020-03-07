# frozen_string_literal: true

require "graphql/fragment_cache/store_adapters/base_store_adapter"
require "graphql/fragment_cache/store_adapters/memory_store_adapter"
require "graphql/fragment_cache/store_adapters/redis_store_adapter"

module GraphQL
  module FragmentCache
    # Contains factory methods for store adapters
    module StoreAdapters
      module_function

      def build(adapter, options = nil)
        if adapter.is_a?(StoreAdapters::BaseStoreAdapter)
          adapter
        else
          build_by_name(adapter, options)
        end
      end

      def build_by_name(name, options)
        const_get("#{camelize(name)}StoreAdapter").new(options || {})
      rescue NameError => e
        raise e.class, "Fragment cache store adapter for :#{name} haven't been found", e.backtrace
      end

      def camelize(str)
        str.to_s.split("_").map(&:capitalize).join
      end
    end
  end
end
