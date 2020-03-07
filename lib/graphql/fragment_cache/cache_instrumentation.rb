# frozen_string_literal: true

require "graphql/fragment_cache/cacher"

module GraphQL
  module FragmentCache
    # Adds hook for saving cached values after query is resolved
    module CacheInstrumentation
      module_function

      def before_query(query); end

      def after_query(query)
        return unless query.valid?

        Cacher.new(query).perform
      end
    end
  end
end
