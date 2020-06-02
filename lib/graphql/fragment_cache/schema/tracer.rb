# frozen_string_literal: true

module GraphQL
  # Plugin definition
  module FragmentCache
    module Schema
      class Tracer
        using Ext

        class << self
          def trace(key, data)
            yield.tap do |resolved_value|
              next unless connection_to_cache?(key, data)

              # We need to attach connection object to fragment and save it later
              context = data[:query].context
              verify_connections!(context)
              cache_connection(resolved_value, context)
            end
          end

          private

          def connection_to_cache?(key, data)
            key == "execute_field" && data[:field].connection?
          end

          def verify_connections!(context)
            return if context.schema.new_connections?

            raise StandardError,
              "GraphQL::Pagination::Connections should be enabled for connection caching"
          end

          def cache_connection(resolved_value, context)
            current_path = context.namespace(:interpreter)[:current_path]
            fragment = context.fragments.find { |fragment| fragment.path == current_path }
            fragment.resolved_value = resolved_value if fragment
          end
        end
      end
    end
  end
end
