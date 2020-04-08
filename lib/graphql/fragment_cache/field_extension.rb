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
      end

      def resolve(object:, arguments:, **_options)
        object.cache_fragment(@cache_options) { yield(object, arguments) }
      end
    end
  end
end