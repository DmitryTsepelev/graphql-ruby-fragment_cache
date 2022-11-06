# frozen_string_literal: true

module GraphQL
  module FragmentCache
    using Ext

    class WriteError < StandardError
      attr_reader :key, :value, :original_error

      def initialize(original_error, key, value)
        @original_error = original_error
        @key = key
        @value = value

        super(original_error.message)
      end
    end

    class WriteMultiError < StandardError
      attr_reader :values, :original_error

      def initialize(original_error, values)
        @original_error = original_error
        @values = values

        super(original_error.message)
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
          select_valid_fragments(query).group_by(&:options).each do |options, group|
            hash = group.map { |fragment| [fragment.cache_key, fragment.value] }.to_h

            begin
              FragmentCache.cache_store.write_multi(hash, **options)
            rescue => e
              raise WriteMultiError.new(e, hash)
            end
          end
        end

        def persist(query)
          select_valid_fragments(query).each do |fragment|
            FragmentCache.cache_store.write(fragment.cache_key, fragment.value, **fragment.options)
          rescue => e
            raise WriteError.new(e, fragment.cache_key, fragment.value)
          end
        end

        def select_valid_fragments(query)
          query.context.fragments.select(&:with_final_value?)
        end
      end
    end
  end
end
