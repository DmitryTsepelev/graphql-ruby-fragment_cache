# frozen_string_literal: true

using RubyNext

module GraphQL
  module FragmentCache
    module GraphRubyVersion
      module_function

      def after_2_2_5?
        check_graphql_version "> 2.2.5"
      end

      def check_graphql_version(predicate)
        Gem::Dependency.new("graphql", predicate).match?("graphql", GraphQL::VERSION)
      end
    end
  end
end
