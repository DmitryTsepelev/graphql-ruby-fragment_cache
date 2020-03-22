# frozen_string_literal: true

module GraphQL
  module FragmentCache
    # Wraps resolver with cache method
    class CacheFragmentExtension < GraphQL::Schema::FieldExtension
      def initialize(options:, **_rest)
        @cache_options = options || {}
      end

      def resolve(object:, arguments:, **_options)
        object.cache_fragment(@cache_options) { yield(object, arguments) }
      end
    end
  end
end
