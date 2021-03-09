# frozen_string_literal: true

module GraphQL
  module FragmentCache
    using Ext

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
            FragmentCache.cache_store.write_multi(hash, **options)
          end
        end

        def persist(query)
          select_valid_fragments(query).each do |fragment|
            FragmentCache.cache_store.write(fragment.cache_key, fragment.value, **fragment.options)
          end
        end

        def select_valid_fragments(query)
          query.context.fragments.select(&:with_final_value?)
        end
      end
    end
  end
end
