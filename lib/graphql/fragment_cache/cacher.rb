# frozen_string_literal: true

module GraphQL
  module FragmentCache
    # Saves resolved fragment values to cache store
    class Cacher
      def initialize(query)
        @query = query
      end

      def perform
        fragments.each do |fragment|
          value = fragment.resolve(final_value)
          FragmentCache.cache_store.write(fragment.cache_key, value, expires_in: fragment.expires_in)
        end
      end

      private

      def final_value
        @final_value ||= @query.context.namespace(:interpreter)[:runtime].final_value
      end

      def fragments
        @fragments ||= @query.context.namespace(:fragment_cache)[:fragments] || []
      end
    end
  end
end
