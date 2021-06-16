# frozen_string_literal: true

require "graphql/fragment_cache/schema/lazy_cache_resolver"
require "graphql/fragment_cache/ext/graphql_cache_key"

module GraphQL
  module FragmentCache
    using Ext
    # Wraps resolver with cache method
    class FieldExtension < GraphQL::Schema::FieldExtension
      module Patch
        def initialize(*args, **kwargs, &block)
          cache_fragment = kwargs.delete(:cache_fragment)

          if cache_fragment
            kwargs[:extensions] ||= []
            kwargs[:extensions] << build_extension(cache_fragment)
          end

          super
        end

        private

        def build_extension(options)
          if options.is_a?(Hash)
            {FieldExtension => options}
          else
            FieldExtension
          end
        end
      end

      def initialize(options:, **_rest)
        @cache_options = GraphQL::FragmentCache.default_options.merge(options || {})
        @cache_options[:default_options_merged] = true

        @context_key = @cache_options.delete(:context_key)
        @cache_key = @cache_options.delete(:cache_key)
      end

      NOT_RESOLVED = Object.new

      def resolve(object:, arguments:, **_options)
        resolved_value = NOT_RESOLVED

        if @cache_options[:if].is_a?(Proc)
          @cache_options[:if] = object.instance_exec(&@cache_options[:if])
        end
        if @cache_options[:unless].is_a?(Proc)
          @cache_options[:unless] = object.instance_exec(&@cache_options[:unless])
        end

        object_for_key = if @context_key
          Array(@context_key).map { |key| object.context[key] }
        elsif @cache_key == :object
          object.object
        elsif @cache_key == :value
          resolved_value = yield(object, arguments)
        end
        cache_fragment_options = @cache_options.merge(object: object_for_key)

        Schema::LazyCacheResolver.new(_options[:context]) do
          object.cache_fragment(**cache_fragment_options) do
            resolved_value == NOT_RESOLVED ? yield(object, arguments) : resolved_value
          end
        end
      end
    end
  end
end
