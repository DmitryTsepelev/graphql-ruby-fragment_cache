# frozen_string_literal: true

module GraphQL
  module FragmentCache
    module Ext
      # Adds #_graphql_cache_key method to Object,
      # which just call #graphql_cache_key or #cache_key.
      #
      # For other core classes returns string representation.
      #
      # Raises ArgumentError otherwise.
      #
      # We use a refinement to avoid case/if statements for type checking
      refine Object do
        def _graphql_cache_key
          return graphql_cache_key if respond_to?(:graphql_cache_key)
          return cache_key if respond_to?(:cache_key)
          return to_a._graphql_cache_key if respond_to?(:to_a)

          to_s
        end
      end

      refine Array do
        def _graphql_cache_key
          map { _1._graphql_cache_key }.join("/")
        end
      end

      refine NilClass do
        def _graphql_cache_key
          ""
        end
      end

      refine TrueClass do
        def _graphql_cache_key
          "t"
        end
      end

      refine FalseClass do
        def _graphql_cache_key
          "f"
        end
      end

      refine String do
        def _graphql_cache_key
          self
        end
      end

      refine Symbol do
        def _graphql_cache_key
          to_s
        end
      end

      if RUBY_PLATFORM.match?(/java/i)
        refine Integer do
          def _graphql_cache_key
            to_s
          end
        end

        refine Float do
          def _graphql_cache_key
            to_s
          end
        end
      else
        refine Numeric do
          def _graphql_cache_key
            to_s
          end
        end
      end

      refine Time do
        def _graphql_cache_key
          to_s
        end
      end

      refine Module do
        def _graphql_cache_key
          name
        end
      end
    end
  end
end
