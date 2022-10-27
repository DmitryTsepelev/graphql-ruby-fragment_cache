# frozen_string_literal: true

require "graphql/fragment_cache/schema/lazy_cache_resolver"

module GraphQL
  module FragmentCache
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

        @if = @cache_options.delete(:if)
        @unless = @cache_options.delete(:unless)

        # Make sure we do not modify options, since they're global
        @cache_options.freeze
      end

      NOT_RESOLVED = Object.new

      def resolve(object:, arguments:, **_options)
        resolved_value = NOT_RESOLVED

        if @if.is_a?(Proc) && !object.instance_exec(&@if)
          return yield(object, arguments)
        end
        if @if.is_a?(Symbol) && !object.send(@if)
          return yield(object, arguments)
        end
        if @unless.is_a?(Proc) && object.instance_exec(&@unless)
          return yield(object, arguments)
        end
        if @unless.is_a?(Symbol) && object.send(@unless)
          return yield(object, arguments)
        end

        object_for_key = if @context_key
          Array(@context_key).map { |key| object.context[key] }
        elsif @cache_key == :value
          resolved_value = yield(object, arguments)
        elsif @cache_key.is_a?(Symbol)
          object.send(@cache_key)
        elsif @cache_key.is_a?(Proc)
          object.instance_exec(&@cache_key)
        end

        cache_fragment_options = @cache_options.merge(object: object_for_key)

        object.cache_fragment(**cache_fragment_options) do
          resolved_value == NOT_RESOLVED ? yield(object, arguments) : resolved_value
        end
      end
    end
  end
end
