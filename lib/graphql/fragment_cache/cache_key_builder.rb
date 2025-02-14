# frozen_string_literal: true

require "json"
require "digest"

module GraphQL
  module FragmentCache
    using Ext

    using(Module.new {
      refine Array do
        def traverse_argument(argument)
          return argument unless argument.is_a?(GraphQL::Schema::InputObject)

          "{#{argument.map { "#{_1}:#{traverse_argument(_2)}" }.sort.join(",")}}"
        end

        def to_selections_key
          map { |val|
            children = val.selections.empty? ? "" : "[#{val.selections.to_selections_key}]"

            field_name = val.field.name
            field_alias = val.ast_nodes.map(&:alias).join
            field_name = "#{field_alias}:#{field_name}" unless field_alias.empty?

            unless val.arguments.empty?
              args = val.arguments.map { "#{_1}:#{traverse_argument(_2)}" }.sort.join(",")
              field_name += "(#{args})"
            end

            "#{field_name}#{children}"
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
        def selection_with_alias(name, **kwargs)
          return selection(name, **kwargs) if selects?(name, **kwargs)
          alias_selection(name, **kwargs)
        end
      end
    })

    # Builds cache key for fragment
    class CacheKeyBuilder
      class << self
        def call(**options)
          new(**options).build
        end
      end

      attr_reader :query, :path, :object, :schema

      def initialize(query:, path:, object: nil, **options)
        @object = object
        @query = query
        @schema = query.schema
        @path = path
        @options = options
      end

      def build
        key_parts = [
          GraphQL::FragmentCache.namespace,
          simple_path_cache_key,
          implicit_cache_key,
          object_cache_key
        ]

        key_parts
          .compact
          .map { |key_part| key_part.tr("/", "-") }
          .join("/")
      end

      private

      def implicit_cache_key
        Digest::SHA1.hexdigest("#{schema_cache_key}/#{query_cache_key}")
      end

      def schema_cache_key
        @options.fetch(:schema_cache_key) { schema.schema_cache_key }
      end

      def query_cache_key
        @options.fetch(:query_cache_key) { "#{path_cache_key}[#{selections_cache_key}]" }
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

      def simple_path_cache_key
        return if path_cache_key.nil?

        path_cache_key.split("(").first
      end

      def path_cache_key
        @path_cache_key ||= @options.fetch(:path_cache_key) do
          lookahead = query.lookahead

          path.map { |field_name|
            # Handle cached fields inside collections:
            next field_name if field_name.is_a?(Integer)

            lookahead = lookahead.selection_with_alias(field_name)
            raise "Failed to look ahead the field: #{field_name}" if lookahead.is_a?(::GraphQL::Execution::Lookahead::NullLookahead)

            next lookahead.field.name if lookahead.arguments.empty?

            args = lookahead.arguments.select { include_argument?(_1) }.map { "#{_1}:#{traverse_argument(_2)}" }.sort.join(",")
            "#{lookahead.field.name}(#{args})"
          }.join("/")
        end
      end

      def include_argument?(argument_name)
        return false if @options[:exclude_arguments]&.include?(argument_name)
        return false if @options[:include_arguments] && !@options[:include_arguments].include?(argument_name)
        true
      end

      def traverse_argument(argument)
        return argument unless argument.is_a?(GraphQL::Schema::InputObject)

        "{#{argument.map { include_argument?(_1) ? "#{_1}:#{traverse_argument(_2)}" : nil }.compact.sort.join(",")}}"
      end

      def object_cache_key
        @options[:object_cache_key] || object_key(object)
      end

      def object_key(obj)
        obj&._graphql_cache_key
      end
    end
  end
end
