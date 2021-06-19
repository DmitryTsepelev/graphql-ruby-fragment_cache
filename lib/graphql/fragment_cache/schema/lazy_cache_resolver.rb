require "graphql/fragment_cache/fragment"

module GraphQL
  module FragmentCache
    module Schema
      using Ext
      class LazyCacheResolver
        def initialize(fragment, query_ctx, object_to_cache, &block)
          @fragment = fragment
          @query_ctx = query_ctx
          @object_to_cache = object_to_cache
          @lazy_state = query_ctx[:lazy_cache_resolver_statez] ||= {
            pending_fragments: Set.new,
            resolved_fragments: {}
          }
          @block = block

          @lazy_state[:pending_fragments] << @fragment
        end

        def resolve
          if @lazy_state[:resolved_fragments].key?(@fragment)
            cached = @lazy_state[:resolved_fragments][@fragment]

            if cached
              return cached == Fragment::NIL_IN_CACHE ? nil : GraphQL::Execution::Interpreter::RawValue.new(obj)
            end
          else
            resolved_fragments = Fragment.read_multi(@lazy_state[:pending_fragments].to_a)
            @lazy_state[:pending_fragments].clear
            resolved_fragments.each { |key, value| @lazy_state[:resolved_fragments][key] = value }

            @lazy_state[:resolved_fragments]
          end

          (block_given? ? block.call : @object_to_cache).tap do |resolved_value|
            @query_ctx.fragments << @fragment
          end
        end
      end
    end
  end
end