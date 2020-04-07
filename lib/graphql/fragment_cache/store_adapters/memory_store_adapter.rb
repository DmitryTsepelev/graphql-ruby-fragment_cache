# frozen_string_literal: true

module GraphQL
  module FragmentCache
    module StoreAdapters
      # Memory adapter for storing cached fragments
      class MemoryStoreAdapter < BaseStoreAdapter
        class Entry < Struct.new(:value, :expires_at, keyword_init: true)
          def expired?
            expires_at && expires_at < Time.now
          end
        end

        attr_reader :default_expires_in

        def initialize(expires_in: nil, **)
          @default_expires_in = expires_in
          @storage = {}
        end

        def get(key)
          storage[key]&.then do |entry|
            if entry.expired?
              del(key)
              next
            end
            entry.value
          end
        end

        def set(key, value, expires_in: default_expires_in, **options)
          @storage[key] = Entry.new(value: value, expires_at: expires_in ? Time.now + expires_in : nil)
        end

        def del(key)
          storage.delete(key)
        end

        private

        attr_reader :storage
      end
    end
  end
end
