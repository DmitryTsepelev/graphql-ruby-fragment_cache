# frozen_string_literal: true

module GraphQL
  module FragmentCache
    module Ext
      # Add ability to access fragments via `context.fragments`
      # without dupclicating the storage logic and monkey-patching
      refine GraphQL::Query::Context do
        def fragments?
          namespace(:fragment_cache)[:fragments]
        end

        def fragments
          namespace(:fragment_cache)[:fragments] ||= []
        end
      end
    end
  end
end
