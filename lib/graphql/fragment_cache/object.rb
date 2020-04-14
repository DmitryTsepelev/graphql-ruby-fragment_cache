# frozen_string_literal: true

require "graphql/fragment_cache/object_helpers"
require "graphql/fragment_cache/field_extension"

module GraphQL
  module FragmentCache
    # Adds #cache_fragment method and kwarg option
    module Object
      def self.included(base)
        base.include(GraphQL::FragmentCache::ObjectHelpers)
        base.field_class.prepend(GraphQL::FragmentCache::FieldExtension::Patch)
      end
    end
  end
end
