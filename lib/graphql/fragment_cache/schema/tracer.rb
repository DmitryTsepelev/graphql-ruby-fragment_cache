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
              next unless connection_field?(key, data)

              verify_connections!(data[:query].context)
            end
          end

          private

          def connection_field?(key, data)
            key == "execute_field" && data[:field].connection?
          end

          def verify_connections!(context)
            return if context.schema.new_connections?

            raise StandardError,
              "GraphQL::Pagination::Connections should be enabled for connection caching"
          end
        end
      end
    end
  end
end
