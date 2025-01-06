# frozen_string_literal: true

require "graphql/fragment_cache/fragment"
require "graphql/fragment_cache/schema/lazy_cache_resolver"

module GraphQL
  module FragmentCache
    using Ext

    # Adds #cache_fragment method
    module ObjectHelpers
      extend Forwardable

      def self.included(base)
        return if base.method_defined?(:raw_value)

        base.include(Module.new {
          def raw_value(obj)
            GraphQL::Execution::Interpreter::RawValue.new(obj)
          end
        })
      end

      NO_OBJECT = Object.new

      def cache_fragment(object_to_cache = NO_OBJECT, **options, &block)
        raise ArgumentError, "Block or argument must be provided" unless block || object_to_cache != NO_OBJECT
        unless GraphQL::FragmentCache.enabled
          return block ? block.call : object_to_cache
        end

        unless options.delete(:default_options_merged)
          options = GraphQL::FragmentCache.default_options.merge(options)
        end

        if options.key?(:if) || options.key?(:unless)
          disabled = options.key?(:if) ? !options.delete(:if) : options.delete(:unless)
          if disabled
            return block ? block.call : object_to_cache
          end
        end

        options[:object] = object_to_cache if object_to_cache != NO_OBJECT

        context_to_use = options.delete(:context)
        context_to_use = context if context_to_use.nil? && respond_to?(:context)
        raise ArgumentError, "cannot find context, please pass it explicitly" unless context_to_use

        fragment = Fragment.new(context_to_use, **options)

        if options.delete(:dataloader)
          # the following line will block the current fiber until Dataloader is resolved, and we will
          # use the resolved value as the `object_to_cache`
          object_to_cache = block.call
          block = nil
        end

        GraphQL::FragmentCache::Schema::LazyCacheResolver.new(fragment, context_to_use, object_to_cache, &block)
      end
    end
  end
end
