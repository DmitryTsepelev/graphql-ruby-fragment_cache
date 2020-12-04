# frozen_string_literal: true

module GraphQL
  module FragmentCache
    using Ext

    class WriteError < StandardError
      attr_reader :key, :value

      def initialize(message, key, value)
        @key = key
        @value = value

        super(message)
      end
    end

    class WriteMultiError < StandardError
      attr_reader :values

      def initialize(message, values)
        @values = values

        super(message)
      end
    end

    # Saves resolved fragment values to cache store
    module Cacher
      class << self
        def call(query)
          return unless query.context.fragments?

          if FragmentCache.cache_store.respond_to?(:write_multi)
            batched_persist(query)
          else
            persist(query)
          end
        end

        private

        def batched_persist(query)
          query.context.fragments.group_by(&:options).each do |options, group|
            hash = group.map { |fragment| [fragment.cache_key, fragment.value] }.to_h

            begin
              FragmentCache.cache_store.write_multi(hash, **options)
            rescue => e
              raise WriteMultiError.new(e.message, hash)
            end
          end
        end

        def persist(query)
          query.context.fragments.each do |fragment|
            FragmentCache.cache_store.write(fragment.cache_key, fragment.value, **fragment.options)
          rescue => e
            raise WriteError.new(e.message, fragment.cache_key, fragment.value)
          end
        end
      end
    end
  end
end
