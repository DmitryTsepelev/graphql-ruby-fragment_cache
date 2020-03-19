# frozen_string_literal: true

module GraphQL
  module FragmentCache
    # Patches field class to add caching extension
    module FieldClassPatch
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
          { CacheFragmentExtension => options }
        else
          CacheFragmentExtension
        end
      end
    end
  end
end
