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
          return unless query.valid?

          Cacher.call(query)
        end
      end
    end
  end
end
