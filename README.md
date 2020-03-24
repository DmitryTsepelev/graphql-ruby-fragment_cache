# GraphQL::FragmentCache [![Build Status](https://travis-ci.org/DmitryTsepelev/graphql-ruby-fragment_cache.svg?branch=master)](https://travis-ci.org/DmitryTsepelev/graphql-ruby-fragment_cache)

🚧**UNDER CONSTUCTION**🚧

`GraphQL::FragmentCache` powers up [graphql-ruby](https://graphql-ruby.org) with the ability to cache _fragments_ of the response: you can mark any field as cached and it will never be resolved again (at least, while cache is valid). For instance, the following code caches `title` for each post:

```ruby
class PostType < BaseObject
  field :id, ID, null: false
  field :title, String, null: false, cache_fragment: true
end
```

<p align="center">
  <a href="https://evilmartians.com/?utm_source=graphql-ruby-fragment_cache">
    <img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54">
  </a>
</p>

## Getting started

Add the gem to your Gemfile `gem 'graphql-fragment_cache'` and add the plugin to your schema class (make sure to turn interpreter mode on!):

```ruby
class GraphqSchema < GraphQL::Schema
  use GraphQL::Execution::Interpreter
  use GraphQL::Analysis::AST

  use GraphQL::FragmentCache

  query QueryType
end
```

Include `GraphQL::FragmentCache::Object` to your base type class:

```ruby
class BaseType < GraphQL::Schema::Object
  include GraphQL::FragmentCache::Object
end
```

Now you can add `cache_fragment:` option to your fields to turn caching on:

```ruby
class PostType < BaseObject
  field :id, ID, null: false
  field :title, String, null: false, cache_fragment: true
end
```

Alternatively, you can use `cache_fragment` method inside resolvers:

```ruby
class QueryType < BaseObject
  field :post, PostType, null: true do
    argument :id, ID, required: true
  end

  def post(id:)
    cache_fragment { Post.find(id) }
  end
end
```

## Cache storage

Cache is stored in memory by default. You can easily switch to Redis (make sure you have [redis](https://github.com/redis/redis-rb) gem installed):

```ruby
class GraphqSchema < GraphQL::Schema
  use GraphQL::Execution::Interpreter
  use GraphQL::Analysis::AST

  use GraphQL::FragmentCache,
      store: :redis,
      redis_client: { redis_host: "127.0.0.2", redis_port: "2214", redis_db_name: "7" }
  # or
  use GraphQL::FragmentCache,
      store: :redis,
      redis_client: Redis.new(url: "redis://127.0.0.2:2214/7")
  # or
  use GraphQL::FragmentCache,
      store: :redis,
      redis_client: ConnectionPool.new { Redis.new(url: "redis://127.0.0.2:2214/7") }

  query QueryType
end
```

You can also override default expiration time and namespace:

```ruby
class GraphqSchema < GraphQL::Schema
  use GraphQL::Execution::Interpreter
  use GraphQL::Analysis::AST

  use GraphQL::FragmentCache,
      store: :redis,
      expiration: 172800, # optional, default is 24 hours
      namespace: "my-custom-namespace"m # optional, default is "graphql-fragment-cache"
      redis_client: { redis_host: "127.0.0.2", redis_port: "2214", redis_db_name: "7" }

  query QueryType
end
```

When Redis storage is configured you can pass `ex` parameter to `cache_fragment`:

```ruby
class PostType < BaseObject
  field :id, ID, null: false
  field :title, String, null: false, cache_fragment: { ex: 2.hours.to_i }
end

class QueryType < BaseObject
  field :post, PostType, null: true do
    argument :id, ID, required: true
  end

  def post(id:)
    cache_fragment(ex: 2.hours.to_i) { Post.find(id) }
  end
end
```

## Key building

Keys are generated automatically. Key is a hexdigest of the payload, while payload includes the following:

- hexdigest of schema definition (to make sure cache is cleared when schema changes)
- query fingerprint, which consists of path to the field with arguments and nested selections

Let's take a look at the example:

```ruby
query = <<~GQL
  query {
    post(id: 1) {
      id
      title
      cachedAuthor {
        id
        name
      }
    }
  }
GQL


payload = {
  schema_cache_key: GraphqSchema.schema_cache_key,
  query_cache_key: {
    path_cache_key: ["post(id:1)", "cachedAuthor"],
    selections_cache_key: { "cachedAuthor" => %w[id name] }
  },
}

key = Digest::SHA1.hexdigest(payload.to_json)
```

You can override `fragment_cache_namespace`, `schema_cache_key` or `query_cache_key` by passing parameters to the `cache_fragment` calls:

```ruby
class QueryType < BaseObject
  field :post, PostType, null: true do
    argument :id, ID, required: true
  end

  def post(id:)
    cache_fragment(query_cache_key: "post(#{id})") { Post.find(id) }
  end
end
```

Same for the short version:

```ruby
class PostType < BaseObject
  field :id, ID, null: false
  field :title, String, null: false, cache_fragment: { query_cache_key: "post_title" }
end
```

Some queries are _context–dependent_: the same query will produce different results depending on a context. For instance, imagine a query that allows to fetch some information about current user:

```gql
query {
  user {
    email
  }
}
```

In order to represent context in the cache key we should tell the plugin what to look for:

```ruby
class GraphqSchema < GraphQL::Schema
  use GraphQL::Execution::Interpreter
  use GraphQL::Analysis::AST

  # we want to take :current_user_id from context
  use GraphQL::FragmentCache, context_key: :current_user_id

  query QueryType
end
```

You can use lambda if you need more control:

```ruby
class GraphqSchema < GraphQL::Schema
  use GraphQL::Execution::Interpreter
  use GraphQL::Analysis::AST

  use GraphQL::FragmentCache, context_key: ->(context) { context[:current_user_id] }

  query QueryType
end
```

In order to include the context key to the cache key you should pass `:context_dependent` option to `cache_fragment`:

```ruby
class PostType < BaseObject
  field :id, ID, null: false
  field :title, String, null: false, cache_fragment: { context_dependent: true }
end

class QueryType < BaseObject
  field :post, PostType, null: true do
    argument :id, ID, required: true
  end

  def post(id:)
    cache_fragment(context_dependent: true) { Post.find(id) }
  end
end
```

Of course, you can override `context_key` for any field you need:

```ruby
class PostType < BaseObject
  field :id, ID, null: false
  field :title, String, null: false, cache_fragment: { context_key: "custom_context_key" }
end
```

## Credits

Based on the original [gist](https://gist.github.com/palkan/faad9f6ff1db16fcdb1c071ec50e4190) by [@palkan](https://github.com/palkan) and [@ssnickolay](https://github.com/ssnickolay).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
