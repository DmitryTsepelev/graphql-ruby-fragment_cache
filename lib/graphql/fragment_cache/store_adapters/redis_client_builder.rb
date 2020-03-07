# frozen_string_literal: true

module GraphQL
  module FragmentCache
    module StoreAdapters
      # Builds Redis object instance based on passed hash
      class RedisClientBuilder
        def initialize(redis_url: nil, redis_host: nil, redis_port: nil, redis_db_name: nil)
          require "redis"

          @redis_url = redis_url
          @redis_host = redis_host
          @redis_port = redis_port
          @redis_db_name = redis_db_name
        rescue LoadError => e
          msg = "Could not load the 'redis' gem, please add it to your gemfile or " \
                "configure a different adapter, e.g. use GraphQL::FragmentCache, store: :memory"
          raise e.class, msg, e.backtrace
        end

        def build
          if @redis_url && (@redis_host || @redis_port || @redis_db_name)
            raise ArgumentError, "redis_url cannot be passed along with redis_host, redis_port " \
                                 "or redis_db_name options"
          end

          ::Redis.new(url: @redis_url || build_redis_url)
        end

        private

        DEFAULT_REDIS_DB = "0"

        def build_redis_url
          db_name = @redis_db_name || DEFAULT_REDIS_DB
          base_url = ENV["REDIS_URL"] || "redis://#{@redis_host}:#{@redis_port}"
          URI.join(base_url, db_name).to_s
        end
      end
    end
  end
end
