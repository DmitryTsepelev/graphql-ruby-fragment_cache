# frozen_string_literal: true

module GraphQL
  module FragmentCache
    # Memory adapter for storing cached fragments
    class MemoryStore
      class Entry < Struct.new(:value, :expires_at, keyword_init: true)
        def expired?
          expires_at && expires_at < Time.now
        end
      end

      attr_reader :default_expires_in

      def initialize(expires_in: nil, **other)
        raise ArgumentError, "Unsupported options: #{other.keys.join(",")}" unless other.empty?

        @default_expires_in = expires_in
        @storage = {}
      end

      def keys
        storage.keys
      end

      def exist?(key)
        storage.key?(key)
      end

      def read(key)
        key = key.to_s
        storage[key]&.then do |entry|
          if entry.expired?
            delete(key)
            next
          end
          entry.value
        end
      end

      def write(key, value, options = {})
        expires_in = options[:expires_in] || default_expires_in
        key = key.to_s
        @storage[key] = Entry.new(value: value, expires_at: expires_in ? Time.now + expires_in : nil)
      end

      def delete(key)
        key = key.to_s
        storage.delete(key)
      end

      def clear
        storage.clear
      end

      private

      attr_reader :storage
    end
  end
end
