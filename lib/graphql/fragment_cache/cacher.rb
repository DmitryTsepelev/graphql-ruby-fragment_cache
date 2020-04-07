# frozen_string_literal: true

module GraphQL
  module FragmentCache
    using Ext

    # Saves resolved fragment values to cache store
    module Cacher
      class << self
        def call(query)
          return unless query.context.fragments?

          final_value = query.context.namespace(:interpreter)[:runtime].final_value

          query.context.fragments.each { |fragment| fragment.persist(final_value) }
        end
      end
    end
  end
end
