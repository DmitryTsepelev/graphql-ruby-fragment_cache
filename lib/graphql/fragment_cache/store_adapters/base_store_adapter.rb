# frozen_string_literal: true

module GraphQL
  module FragmentCache
    module StoreAdapters
      # Base class for all store adapters
      class BaseStoreAdapter
        def initialize(_options); end

        def get(_key)
          raise NotImplementedError
        end

        def set(_key, _value)
          raise NotImplementedError
        end

        def del(_key)
          raise NotImplementedError
        end
      end
    end
  end
end
