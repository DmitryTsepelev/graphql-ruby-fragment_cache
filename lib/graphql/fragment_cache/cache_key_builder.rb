# frozen_string_literal: true

require "json"
require "digest"

using RubyNext

module GraphQL
  module FragmentCache
    using Ext

    using(Module.new {
      refine Array do
        def to_selections_key
          map { |val|
            children = val.selections.empty? ? "" : "[#{val.selections.to_selections_key}]"
            "#{val.field.name}#{children}"
          }.join(".")
        end
      end

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

      refine ::GraphQL::Execution::Lookahead do
        using RubyNext

        def selection_with_alias(name, **kwargs)
          # In case of union we have to pass a type of object explicitly
          # More info https://github.com/rmosolgo/graphql-ruby/pull/3007
          if @selected_type.kind.union?
            # TODO: we need to guess a type of an object at path to pass it
            kwargs[:selected_type] = @query.context.namespace(:interpreter)[:current_object].class
          end

          selection(name, **kwargs).then do |next_selection|
            if next_selection.is_a?(GraphQL::Execution::Lookahead::NullLookahead)
              alias_selection(name, **kwargs)
            else
              next_selection
            end
          end
        end

        def alias_selection(name, selected_type: @selected_type, arguments: nil)
          return alias_selections[name] if alias_selections.key?(name)

          alias_node = lookup_alias_node(ast_nodes, name)
          return ::GraphQL::Execution::Lookahead::NULL_LOOKAHEAD unless alias_node

          next_field_name = alias_node.name

          # From https://github.com/rmosolgo/graphql-ruby/blob/1a9a20f3da629e63ea8e5ee8400be82218f9edc3/lib/graphql/execution/lookahead.rb#L91
          next_field_defn = get_class_based_field(selected_type, next_field_name)

          alias_name = "#{name}_#{selected_type.name}"

          alias_selections[alias_name] =
            if next_field_defn
              next_nodes = []
              arguments = @query.arguments_for(alias_node, next_field_defn)
              arguments = arguments.is_a?(::GraphQL::Execution::Interpreter::Arguments) ? arguments.keyword_arguments : arguments
              @ast_nodes.each do |ast_node|
                ast_node.selections.each do |selection|
                  find_selected_nodes(selection, next_field_name, next_field_defn, arguments: arguments, matches: next_nodes)
                end
              end

              if next_nodes.any?
                ::GraphQL::Execution::Lookahead.new(query: @query, ast_nodes: next_nodes, field: next_field_defn, owner_type: selected_type)
              else
                ::GraphQL::Execution::Lookahead::NULL_LOOKAHEAD
              end
            else
              ::GraphQL::Execution::Lookahead::NULL_LOOKAHEAD
            end
        end

        def alias_selections
          return @alias_selections if defined?(@alias_selections)
          @alias_selections ||= {}
        end

        def lookup_alias_node(nodes, name)
          return if nodes.empty?

          nodes.find do |node|
            if node.is_a?(GraphQL::Language::Nodes::FragmentSpread)
              node = @query.fragments[node.name]
              raise("Invariant: Can't look ahead to nonexistent fragment #{node.name} (found: #{@query.fragments.keys})") unless node
            end

            return node if node.alias?(name)
            child = lookup_alias_node(node.children, name)
            return child if child
          end
        end
      end
    })

    # Builds cache key for fragment
    class CacheKeyBuilder
      using RubyNext

      class << self
        def call(**options)
          new(**options).build
        end
      end

      attr_reader :query, :path, :object, :schema

      def initialize(object: nil, query:, path:, **options)
        @object = object
        @query = query
        @schema = query.schema
        @path = path
        @options = options
      end

      def build
        Digest::SHA1.hexdigest("#{schema_cache_key}/#{query_cache_key}").then do |base_key|
          next base_key unless object
          "#{base_key}/#{object_key(object)}"
        end
      end

      private

      def schema_cache_key
        @options.fetch(:schema_cache_key, schema.schema_cache_key)
      end

      def query_cache_key
        @options.fetch(:query_cache_key, "#{path_cache_key}[#{selections_cache_key}]")
      end

      def selections_cache_key
        current_root =
          path.reduce(query.lookahead) { |lkhd, field_name|
            # Handle cached fields inside collections:
            next lkhd if field_name.is_a?(Integer)

            lkhd.selection_with_alias(field_name)
          }

        current_root.selections.to_selections_key
      end

      def path_cache_key
        lookahead = query.lookahead

        path.map { |field_name|
          # Handle cached fields inside collections:
          next field_name if field_name.is_a?(Integer)

          lookahead = lookahead.selection_with_alias(field_name)
          raise "Failed to look ahead the field: #{field_name}" if lookahead.is_a?(::GraphQL::Execution::Lookahead::NullLookahead)

          next lookahead.field.name if lookahead.arguments.empty?

          args = lookahead.arguments.map { "#{_1}:#{traverse_argument(_2)}" }.sort.join(",")
          "#{lookahead.field.name}(#{args})"
        }.join("/")
      end

      def traverse_argument(argument)
        return argument unless argument.is_a?(GraphQL::Schema::InputObject)

        "{#{argument.map { "#{_1}:#{traverse_argument(_2)}" }.sort.join(",")}}"
      end

      def object_key(obj)
        obj._graphql_cache_key
      end
    end
  end
end
