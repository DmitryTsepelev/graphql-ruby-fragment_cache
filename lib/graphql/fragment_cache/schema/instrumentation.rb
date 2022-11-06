# frozen_string_literal: true

require "graphql/fragment_cache/cacher"

module GraphQL
  module FragmentCache
    module Schema
      # Adds hook for saving cached values after query is resolved
      module Instrumentation
        module_function

        def before_query(query)
        end

        def after_query(query)
          return if skip_caching?(query)

          Cacher.call(query)
        end

        def skip_caching?(query)
          !query.valid? ||
            GraphQL::FragmentCache.skip_cache_when_query_has_errors? && query.context.errors.any?
        end
      end
    end
  end
end
