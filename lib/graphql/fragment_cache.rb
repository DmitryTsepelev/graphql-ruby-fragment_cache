# frozen_string_literal: true

require "graphql"

require "graphql/fragment_cache/ext/context_fragments"
require "graphql/fragment_cache/ext/graphql_cache_key"
require "graphql/fragment_cache/object"

require "graphql/fragment_cache/connections/patch"

require "graphql/fragment_cache/schema/patch"
require "graphql/fragment_cache/schema/tracer"
require "graphql/fragment_cache/schema/instrumentation"
require "graphql/fragment_cache/schema/lazy_cache_resolver"

require "graphql/fragment_cache/memory_store"

require "graphql/fragment_cache/version"

module GraphQL
  # Plugin definition
  module FragmentCache
    class << self
      attr_reader :cache_store
      attr_accessor :enabled
      attr_accessor :namespace
      attr_accessor :default_options

      attr_accessor :skip_cache_when_query_has_errors

      def use(schema_defn, options = {})
        verify_interpreter_and_analysis!(schema_defn)

        schema_defn.tracer(Schema::Tracer)
        schema_defn.trace_with(GraphQL::Tracing::LegacyHooksTrace)
        schema_defn.instance_exec { own_instrumenters[:query] << Schema::Instrumentation }

        schema_defn.extend(Schema::Patch)
        schema_defn.lazy_resolve(Schema::LazyCacheResolver, :resolve)

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

      alias_method :skip_cache_when_query_has_errors?, :skip_cache_when_query_has_errors

      def graphql_ruby_before_2_0?
        check_graphql_version "< 2.0.0"
      end

      def graphql_ruby_after_2_0_13?
        check_graphql_version "> 2.0.13"
      end

      def graphql_ruby_before_2_1_4?
        check_graphql_version "< 2.1.4"
      end

      private

      def check_graphql_version(predicate)
        Gem::Dependency.new("graphql", predicate).match?("graphql", GraphQL::VERSION)
      end

      def verify_interpreter_and_analysis!(schema_defn)
        if graphql_ruby_before_2_0?
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
    self.enabled = true
    self.namespace = "graphql"
    self.default_options = {}
    self.skip_cache_when_query_has_errors = false
  end
end

require "graphql/fragment_cache/railtie" if defined?(Rails::Railtie)
