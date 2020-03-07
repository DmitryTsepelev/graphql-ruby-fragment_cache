# frozen_string_literal: true

require "forwardable"

module GraphQL
  module FragmentCache
    # Builds cache key for fragment
    class CacheKeyBuilder
      extend Forwardable

      def_delegators :@context, :schema, :query

      def initialize(context, **options)
        @context = context
        @options = options
      end

      def build
        [
          fragment_cache_namespace,
          schema_cache_key,
          query_cache_key,
          context_cache_key
        ].compact.join(":")
      end

      private

      def interpreter_context
        @interpreter_context ||= @context.namespace(:interpreter)
      end

      def schema_cache_key
        @options[:schema_cache_key] || schema.schema_cache_key
      end

      def fragment_cache_namespace
        @options[:fragment_cache_namespace] || schema.fragment_cache_namespace
      end

      def query_cache_key
        @options[:query_cache_key] || "#{path_cache_key}:#{selections_cache_key}"
      end

      def context_cache_key
        schema.context_cache_key_resolver&.call(query.context)
      end

      def selections_cache_key
        interpreter_context.fetch(:current_path)
                           .reduce(query.lookahead) { |lkhd, name| lkhd.selection(name) }
                           .selections.map { |selection| traverse(selection) }.sort
                           .join(",")
      end

      def path_cache_key
        lookahead = query.lookahead

        fields_with_args = interpreter_context[:current_path].map do |field_name|
          lookahead = lookahead.selection(field_name)

          next field_name if lookahead.arguments.empty?

          args = lookahead.arguments.map { |k, v| "#{k}:#{v}" }.sort.join(",")
          "#{field_name}(#{args})"
        end

        fields_with_args.join("->")
      end

      def traverse(lookahead)
        return lookahead.field.name if lookahead.selections.empty?

        subselections = lookahead.selections.map { |selection| traverse(selection) }.sort.join(",")

        "#{lookahead.field.name}{#{subselections}}"
      end
    end
  end
end
