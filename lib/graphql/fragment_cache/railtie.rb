# frozen_string_literal: true

module GraphQL
  module FragmentCache
    class Railtie < ::Rails::Railtie # :nodoc:
      # Provides Rails-specific configuration,
      # accessible through `Rails.application.config.graphql_fragment_cache`
      module Config
        class << self
          def store=(store)
            # Handle both:
            #   store = :memory
            #   store = :mem_cache, ENV['MEMCACHE']
            if store.is_a?(Symbol) || store.is_a?(Array)
              store = ActiveSupport::Cache.lookup_store(store)
            end

            FragmentCache.cache_store = store
          end
        end
      end

      config.graphql_fragment_cache = Config
    end
  end
end
