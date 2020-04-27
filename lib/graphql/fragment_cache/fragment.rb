# frozen_string_literal: true

require "graphql/fragment_cache/cache_key_builder"

module GraphQL
  module FragmentCache
    # Represents a single fragment to cache
    class Fragment
      attr_reader :options, :path, :context

      def initialize(context, **options)
        @context = context
        @options = options
        @path = normalize_current_path(context)
      end

      def read
        FragmentCache.cache_store.read(cache_key)
      end

      def persist(final_value)
        value = resolve(final_value)
        FragmentCache.cache_store.write(cache_key, value, **options)
      end

      private

      def cache_key
        @cache_key ||= CacheKeyBuilder.call(path: path, query: context.query, **options)
      end

      def resolve(final_value)
        final_value.dig(*path)
      end

      # Replace aliases with field names
      def normalize_current_path(ctx)
        lookahead = context.query.lookahead
        current_path = context.namespace(:interpreter)[:current_path]

        current_path.map do |name|
          field_name = lookahead.selects?(name) ? name : lookup_alias(lookahead.ast_nodes, name)&.name
          raise "Couldn't find graph node for alias: #{name}" unless field_name
          lookahead = lookahead.selection(name)
          field_name
        end
      end

      using(Module.new do
        refine ::GraphQL::Language::Nodes::AbstractNode do
          def alias?(_)
            false
          end
        end

        refine ::GraphQL::Language::Nodes::Field do
          def alias?(val)
            self.alias == val
          end
        end
      end)

      def lookup_alias(nodes, name)
        return if nodes.empty?
        nodes.find do |node|
          return node if node.alias?(name)
          child = lookup_alias(node.children, name)
          return child if child
        end
      end
    end
  end
end
