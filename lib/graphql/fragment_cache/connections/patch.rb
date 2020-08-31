# frozen_string_literal: true

module GraphQL
  module FragmentCache
    module Connections
      # Patches GraphQL::Pagination::Connections to support raw values
      module Patch
        if Gem::Dependency.new("graphql", ">= 1.11.0").match?("graphql", GraphQL::VERSION)
          def wrap(field, parent, items, arguments, context, *options)
            raw_value?(items) ? items : super
          end
        else
          def wrap(field, object, arguments, context, *options)
            raw_value?(object) ? object : super
          end
        end

        private

        def raw_value?(value)
          GraphQL::Execution::Interpreter::RawValue === value
        end
      end
    end
  end
end
