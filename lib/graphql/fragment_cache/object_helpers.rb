# frozen_string_literal: true

require "graphql/fragment_cache/fragment"

module GraphQL
  module FragmentCache
    using Ext

    # Adds #cache_fragment method
    module ObjectHelpers
      NO_OBJECT = Object.new

      def cache_fragment(object_to_cache = NO_OBJECT, **options, &block)
        raise ArgumentError, "Block or argument must be provided" unless block_given? || object_to_cache != NO_OBJECT

        options[:object] = object_to_cache if object_to_cache != NO_OBJECT
        fragment = Fragment.new(context, options)

        if (cached = fragment.read)
          return raw_value(cached)
        end

        context.fragments << fragment

        block_given? ? block.call : object_to_cache
      end
    end
  end
end
