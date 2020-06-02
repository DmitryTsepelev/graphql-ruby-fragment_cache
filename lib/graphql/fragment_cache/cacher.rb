# frozen_string_literal: true

module GraphQL
  module FragmentCache
    using Ext

    # Saves resolved fragment values to cache store
    module Cacher
      class << self
        def call(query)
          return unless query.context.fragments?

          query.context.fragments.each(&:persist)
        end
      end
    end
  end
end
