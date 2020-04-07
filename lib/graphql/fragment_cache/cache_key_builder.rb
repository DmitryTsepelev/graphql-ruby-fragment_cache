# frozen_string_literal: true

require "json"
require "digest"

module GraphQL
  module FragmentCache
    # Builds cache key for fragment
    class CacheKeyBuilder
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
        Digest::SHA1.hexdigest(payload.to_json)
      end

      private

      def payload
        {
          schema_cache_key: schema_cache_key,
          query_cache_key: query_cache_key
        }
      end

      def schema_cache_key
        @options[:schema_cache_key] || schema.schema_cache_key
      end

      def query_cache_key
        @options[:query_cache_key] ||
          {path_cache_key: path_cache_key, selections_cache_key: selections_cache_key}
      end

      def selections_cache_key
        current_root =
          path.reduce(query.lookahead) { |lkhd, name| lkhd.selection(name) }

        traverse(current_root)
      end

      def path_cache_key
        lookahead = query.lookahead

        path.map do |field_name|
          lookahead = lookahead.selection(field_name)

          next field_name if lookahead.arguments.empty?

          args = lookahead.arguments.map { |k, v| "#{k}:#{v}" }.sort.join(",")
          "#{field_name}(#{args})"
        end
      end

      def object_key(obj)
        # TODO: implement me
      end

      def traverse(lookahead)
        field_name = lookahead.field.name
        return field_name if lookahead.selections.empty?

        subselections = lookahead.selections.map { |selection| traverse(selection) }
        {field_name => subselections}
      end
    end
  end
end
