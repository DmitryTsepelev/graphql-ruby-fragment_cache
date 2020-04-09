# frozen_string_literal: true

require "graphql/fragment_cache/fragment"

module GraphQL
  module FragmentCache
    using Ext

    # Adds #cache_fragment method
    module ObjectHelpers
      def cache_fragment(object_to_cache = nil, **options, &block)
        fragment = Fragment.new(context, options)

        if (cached = fragment.read)
          return raw_value(cached)
        end

        context.fragments << fragment

        object_to_cache || block.call
      end
    end
  end
end
