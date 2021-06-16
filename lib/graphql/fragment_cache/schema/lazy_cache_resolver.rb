require "graphql/fragment_cache/fragment"

module GraphQL
  module FragmentCache
    module Schema
      using Ext
      class LazyCacheResolver
        def initialize(query_ctx, object)
          @cache_key = object._graphql_cache_key
          @lazy_state = query_ctx[:lazy_cache_resolver_keys] ||= {
            pending_keys: Set.new,
            resolved_keys: {}
          }
          @lazy_state[:pending_keys] << @cache_key
        end

        def resolve
          resolved_key = @lazy_state[:resolved_keys][@cache_key]
          if resolved_key
            resolved_key
          else
            resolved_key_vals = Fragment.read_multi(@lazy_state[:pending_keys].to_a)
            @lazy_state[:pending_keys].clear
            resolved_key_vals.each { |key, value| @lazy_state[:resolved_keys][key] = value }

            @lazy_state[:resolved_keys][@cache_key]
          end
        end
      end
    end
  end
end