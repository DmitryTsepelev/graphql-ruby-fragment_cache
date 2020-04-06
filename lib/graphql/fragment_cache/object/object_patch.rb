# frozen_string_literal: true

module GraphQL
  module FragmentCache
    module Object
      # Adds #cache_fragment method
      module ObjectPatch
        def cache_fragment(object_to_cache = nil, **options, &block)
          if object_to_cache && block
            raise ArgumentError, "both object and block could not be passed to cache_fragment"
          end

          fragment = Fragment.new(context, options)

          if (cached = read_cached_value(fragment))
            return cached
          end

          fragments << fragment
          object_to_cache || block.call
        end

        private

        def read_cached_value(fragment)
          cached = context.schema.fragment_cache_store.get(fragment.cache_key)
          raw_value(cached) if cached
        end

        def current_path
          @current_path ||= context.namespace(:interpreter)[:current_path]
        end

        def fragments
          context.namespace(:fragment_cache)[:fragments] ||= []
        end
      end
    end
  end
end
