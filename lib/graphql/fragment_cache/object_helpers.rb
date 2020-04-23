# frozen_string_literal: true

require "graphql/fragment_cache/fragment"

module GraphQL
  module FragmentCache
    using Ext

    RawConnection = Struct.new(:items, :nodes, :paged_nodes_offset, :has_previous_page, :has_next_page)

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
          cache_value(resolved_value, fragment)
        end
      end

      private

      def restore_cached_value(cached)
        connection? ? restore_cached_connection(cached) : raw_value(cached)
      end

      def cache_value(resolved_value, fragment)
        if connection?
          unless context.schema.new_connections?
            raise StandardError,
              "GraphQL::Pagination::Connections should be enabled for connection caching"
          end

          connection = wrap_connection(resolved_value)

          fragment.raw_connection = RawConnection.new(
            connection.items,
            connection.nodes,
            connection.instance_variable_get(:@paged_nodes_offset),
            connection.has_previous_page,
            connection.has_next_page
          )
        end

        context.fragments << fragment
      end

      def field
        interpreter_context[:current_field]
      end

      def interpreter_context
        @interpreter_context ||= context.namespace(:interpreter)
      end

      def restore_cached_connection(raw_connection)
        wrap_connection(raw_connection.items).tap do |connection|
          connection.instance_variable_set(:@nodes, raw_connection.nodes)
          connection.instance_variable_set(:@paged_nodes_offset, raw_connection.paged_nodes_offset)
          connection.instance_variable_set(:@has_previous_page, raw_connection.has_previous_page)
          connection.instance_variable_set(:@has_next_page, raw_connection.has_next_page)
        end
      end

      def wrap_connection(object)
        context.schema.connections.wrap(field, object, interpreter_context[:current_arguments], context)
      end
    end
  end
end
