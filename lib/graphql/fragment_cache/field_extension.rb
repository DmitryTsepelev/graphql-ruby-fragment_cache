# frozen_string_literal: true

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
        @cache_options = options || {}

        @context_key = @cache_options.delete(:context_key)
        @cache_key = @cache_options.delete(:cache_key)
      end

      def resolve(object:, arguments:, **_options)
        resolved_value = yield(object, arguments)

        object_for_key = if @context_key
          Array(@context_key).map { |key| object.context[key] }
        elsif @cache_key == :object
          object.object
        elsif @cache_key == :value
          resolved_value
        end

        cache_fragment_options = @cache_options.merge(object: object_for_key)

        object.cache_fragment(cache_fragment_options) { resolved_value }
      end
    end
  end
end
