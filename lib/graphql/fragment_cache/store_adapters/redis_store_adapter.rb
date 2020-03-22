# frozen_string_literal: true

require "graphql/fragment_cache/store_adapters/redis_client_builder"

module GraphQL
  module FragmentCache
    module StoreAdapters
      # Redis adapter for storing fragment cache
      class RedisStoreAdapter < BaseStoreAdapter
        DEFAULT_EXPIRATION = 24 * 60 * 60

        def initialize(redis_client:, expiration: nil)
          @redis_proc = build_redis_proc(redis_client)
          @expiration = expiration || DEFAULT_EXPIRATION
        end

        def get(key)
          @redis_proc.call { |redis| redis.get(key) }
        end

        # rubocop:disable Naming/UncommunicativeMethodParamName
        def set(key, value, ex: nil)
          ex ||= @expiration
          @redis_proc.call { |redis| redis.set(key, value, ex: ex) }
        end
        # rubocop:enable Naming/UncommunicativeMethodParamName

        def del(_key)
          @redis_proc.call { |redis| redis.del(key) }
        end

        private

        # rubocop: disable Metrics/MethodLength
        # rubocop: disable Metrics/CyclomaticComplexity
        # rubocop: disable Metrics/PerceivedComplexity
        def build_redis_proc(redis_client)
          if redis_client.is_a?(Hash)
            build_redis_proc(RedisClientBuilder.new(redis_client).build)
          elsif redis_client.is_a?(Proc)
            redis_client
          elsif defined?(::Redis) && redis_client.is_a?(::Redis)
            proc { |&b| b.call(redis_client) }
          elsif defined?(ConnectionPool) && redis_client.is_a?(ConnectionPool)
            proc { |&b| redis_client.with { |r| b.call(r) } }
          else
            raise ArgumentError, ":redis_client accepts Redis, ConnectionPool, Hash or Proc only"
          end
        end
        # rubocop: enable Metrics/MethodLength
        # rubocop: enable Metrics/CyclomaticComplexity
        # rubocop: enable Metrics/PerceivedComplexity
      end
    end
  end
end
