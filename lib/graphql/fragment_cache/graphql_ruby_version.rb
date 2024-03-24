# frozen_string_literal: true

using RubyNext

module GraphQL
  module FragmentCache
    module GraphRubyVersion
      module_function

      def before_2_0?
        check_graphql_version "< 2.0.0"
      end

      def after_2_0_13?
        check_graphql_version "> 2.0.13"
      end

      def before_2_1_4?
        check_graphql_version "< 2.1.4"
      end

      def after_2_2_5?
        check_graphql_version "> 2.2.5"
      end

      def check_graphql_version(predicate)
        Gem::Dependency.new("graphql", predicate).match?("graphql", GraphQL::VERSION)
      end
    end
  end
end
