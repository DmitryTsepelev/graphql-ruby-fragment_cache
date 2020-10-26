# frozen_string_literal: true

require "graphql/fragment_cache/fragment"

module GraphQL
  module FragmentCache
    using Ext

    # Adds #cache_fragment method
    module ObjectHelpers
      extend Forwardable

      def self.included(base)
        return if base < GraphQL::Execution::Interpreter::HandlesRawValue

        base.include(GraphQL::Execution::Interpreter::HandlesRawValue)
      end

      NO_OBJECT = Object.new

      def cache_fragment(object_to_cache = NO_OBJECT, **options, &block)
        raise ArgumentError, "Block or argument must be provided" unless block_given? || object_to_cache != NO_OBJECT

        options[:object] = object_to_cache if object_to_cache != NO_OBJECT

        context_to_use = options.delete(:context)
        context_to_use = context if context_to_use.nil? && respond_to?(:context)
        raise ArgumentError, "cannot find context, please pass it explicitly" unless context_to_use

        fragment = Fragment.new(context_to_use, options)

        if (cached = fragment.read)
          return cached == Fragment::NIL_IN_CACHE ? nil : raw_value(cached)
        end

        (block_given? ? block.call : object_to_cache).tap do |resolved_value|
          context_to_use.fragments << fragment
        end
      end
    end
  end
end
