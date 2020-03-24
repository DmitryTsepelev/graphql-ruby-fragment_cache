# frozen_string_literal: true

require "graphql/fragment_cache/object/object_patch"
require "graphql/fragment_cache/object/field_class_patch"

module GraphQL
  module FragmentCache
    # Adds #cache_fragment method and kwarg option
    module Object
      def self.included(base)
        base.include(GraphQL::FragmentCache::Object::ObjectPatch)
        base.field_class.prepend(GraphQL::FragmentCache::Object::FieldClassPatch)
      end
    end
  end
end
