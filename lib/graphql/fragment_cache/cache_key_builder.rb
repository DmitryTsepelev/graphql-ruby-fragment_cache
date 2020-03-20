# frozen_string_literal: true

require "forwardable"
require "json"
require "digest"

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
        "#{fragment_cache_namespace}:#{Digest::SHA1.hexdigest(payload.to_json)}"
      end

      private

      def payload
        {
          schema_cache_key: schema_cache_key,
          query_cache_key: query_cache_key,
          context_cache_key: context_cache_key
        }
      end

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
        @options[:query_cache_key] ||
          { path_cache_key: path_cache_key, selections_cache_key: selections_cache_key }
      end

      def context_cache_key
        return @options[:context_cache_key] if @options[:context_cache_key]
        return unless @options[:context_dependent]

        schema.context_cache_key_resolver.then do |resolver|
          case resolver
          when Proc then resolver.call(query.context)
          when Symbol then query.context[resolver]
          end
        end
      end

      def selections_cache_key
        current_root =
          interpreter_context.fetch(:current_path)
                             .reduce(query.lookahead) { |lkhd, name| lkhd.selection(name) }

        traverse(current_root)
      end

      def path_cache_key
        lookahead = query.lookahead

        interpreter_context[:current_path].map do |field_name|
          lookahead = lookahead.selection(field_name)

          next field_name if lookahead.arguments.empty?

          args = lookahead.arguments.map { |k, v| "#{k}:#{v}" }.sort.join(",")
          "#{field_name}(#{args})"
        end
      end

      def traverse(lookahead)
        field_name = lookahead.field.name
        return field_name if lookahead.selections.empty?

        subselections = lookahead.selections.map { |selection| traverse(selection) }
        { field_name => subselections }
      end
    end
  end
end
