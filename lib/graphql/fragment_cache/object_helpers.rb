# frozen_string_literal: true

require "graphql/fragment_cache/fragment"

module GraphQL
  module FragmentCache
    using Ext

    # Adds #cache_fragment method
    module ObjectHelpers
      extend Forwardable

      NO_OBJECT = Object.new

      def_delegator :field, :connection?

      def cache_fragment(object_to_cache = NO_OBJECT, **options, &block)
        raise ArgumentError, "Block or argument must be provided" unless block_given? || object_to_cache != NO_OBJECT

        options[:object] = object_to_cache if object_to_cache != NO_OBJECT

        fragment = Fragment.new(context, options)

        if (cached = fragment.read)
          return restore_cached_value(cached)
        end

        (block_given? ? block.call : object_to_cache).tap do |resolved_value|
          context.fragments << fragment
        end
      end

      private

      def restore_cached_value(cached)
        # If we return connection object from resolver, Interpreter stops processing it
        connection? ? cached : raw_value(cached)
      end

      def field
        interpreter_context[:current_field]
      end

      def interpreter_context
        @interpreter_context ||= context.namespace(:interpreter)
      end
    end
  end
end
