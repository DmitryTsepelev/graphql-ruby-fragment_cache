# frozen_string_literal: true

require "graphql"

require "graphql/fragment_cache/ext/context_fragments"
require "graphql/fragment_cache/ext/graphql_cache_key"
require "graphql/fragment_cache/object"

require "graphql/fragment_cache/connections/patch"

require "graphql/fragment_cache/schema/patch"
require "graphql/fragment_cache/schema/tracer"
require "graphql/fragment_cache/schema/instrumentation"

require "graphql/fragment_cache/memory_store"

require "graphql/fragment_cache/version"

module GraphQL
  # Plugin definition
  module FragmentCache
    class << self
      attr_reader :cache_store
      attr_accessor :namespace

      def use(schema_defn, options = {})
        verify_interpreter_and_analysis!(schema_defn)

        schema_defn.tracer(Schema::Tracer)
        schema_defn.instrument(:query, Schema::Instrumentation)
        schema_defn.extend(Schema::Patch)

        GraphQL::Pagination::Connections.prepend(Connections::Patch)
      end

      def configure
        yield self
      end

      def cache_store=(store)
        unless store.respond_to?(:read)
          raise ArgumentError, "Store must implement #read(key) method"
        end

        unless store.respond_to?(:write)
          raise ArgumentError, "Store must implement #write(key, val, **options) method"
        end

        @cache_store = store
      end

      def graphql_ruby_1_12_or_later?
        Gem::Dependency.new("graphql", ">= 1.12.0").match?("graphql", GraphQL::VERSION)
      end

      private

      def verify_interpreter_and_analysis!(schema_defn)
        if graphql_ruby_1_12_or_later?
          unless schema_defn.interpreter?
            raise StandardError,
              "GraphQL::Execution::Execute should not be enabled for fragment caching"
          end

          unless schema_defn.analysis_engine == GraphQL::Analysis::AST
            raise StandardError,
              "GraphQL::Analysis should not be enabled for fragment caching"
          end
        else
          unless schema_defn.interpreter?
            raise StandardError,
              "GraphQL::Execution::Interpreter should be enabled for fragment caching"
          end

          unless schema_defn.analysis_engine == GraphQL::Analysis::AST
            raise StandardError,
              "GraphQL::Analysis::AST should be enabled for fragment caching"
          end
        end
      end
    end

    self.cache_store = MemoryStore.new
  end
end

require "graphql/fragment_cache/railtie" if defined?(Rails::Railtie)
