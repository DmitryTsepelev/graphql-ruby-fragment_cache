# frozen_string_literal: true

module GraphQL
  module FragmentCache
    module Object
      # Adds #cache_fragment method
      module ObjectPatch
        def cache_fragment(options = {}, &block)
          fragment ||= Fragment.new(context, options)
          read_cached_value(fragment) || eval_end_store(fragment, &block)
        end

        private

        def read_cached_value(fragment)
          cached = context.schema.fragment_cache_store.get(fragment.cache_key)
          raw_value(cached) if cached
        end

        def eval_end_store(fragment, &block)
          fragments << fragment
          block.call
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
