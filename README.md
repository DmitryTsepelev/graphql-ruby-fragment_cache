# GraphQL::FragmentCache ![CI](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/workflows/CI/badge.svg?branch=master)

`GraphQL::FragmentCache` powers up [graphql-ruby](https://graphql-ruby.org) with the ability to cache response _fragments_: you can mark any field as cached and it will never be resolved again (at least, while cache is valid). For instance, the following code caches `title` for each post:

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

Add the gem to your Gemfile `gem 'graphql-fragment_cache'` and add the plugin to your schema class (make sure to turn interpreter mode on with AST analysis!):

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

If you're using [resolvers](https://graphql-ruby.org/fields/resolvers.html) — include the module into the base resolver as well:

```ruby
class Resolvers::BaseResolver < GraphQL::Schema::Resolver
  include GraphQL::FragmentCache::ObjectHelpers
end
```

Now you can add `cache_fragment:` option to your fields to turn caching on:

```ruby
class PostType < BaseObject
  field :id, ID, null: false
  field :title, String, null: false, cache_fragment: true
end
```

Alternatively, you can use `cache_fragment` method inside resolver methods:

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

If you use [connections](https://graphql-ruby.org/pagination/connection_concepts.html) and plan to cache them—please turn on [brand new](https://github.com/rmosolgo/graphql-ruby/blob/master/lib/graphql/pagination/connections.rb#L5) connections hierarchy in your schema:

```ruby
class GraphqSchema < GraphQL::Schema
  # ...
  use GraphQL::Pagination::Connections
end
```

## Cache key generation

Cache keys consist of the following parts: namespace, implicit key, and explicit key.

### Cache namespace

You can optionally define a namespace that will be prefixed to every cache key:

```ruby
GraphQL::FragmentCache.namespace = "my-prefix"
```

### Implicit cache key

Implicit part of a cache key contains the information about the schema and the current query. It includes:

- Hex gsdigest of the schema definition (to make sure cache is cleared when the schema changes).
- The current query fingerprint consisting of a _path_ to the field, arguments information and the selections set.

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

schema_cache_key = GraphqSchema.schema_cache_key

path_cache_key = "post(id:1)/cachedAuthor"
selections_cache_key = "[#{%w[id name].join(".")}]"

query_cache_key = Digest::SHA1.hexdigest("#{path_cache_key}#{selections_cache_key}")

cache_key = "#{schema_cache_key}/#{query_cache_key}/#{object_cache_key}"
```

You can override `schema_cache_key`, `query_cache_key`, `path_cache_key` or `object_cache_key` by passing parameters to the `cache_fragment` calls:

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

Overriding `path_cache_key` might be helpful when you resolve the same object nested in multiple places (e.g., `Post` and `Comment` both have `author`), but want to make sure cache will be invalidated when selection set is different.

Same for the option:

```ruby
class PostType < BaseObject
  field :id, ID, null: false
  field :title, String, null: false, cache_fragment: {query_cache_key: "post_title"}
end
```

Overriding `object_cache_key` is helpful in the case where the value that is cached is different than the one used as a key, like a database query that is pre-processed before caching.

```ruby
class QueryType < BaseObject
  field :post, PostType, null: true do
    argument :id, ID, required: true
  end

  def post(id:)
    query = Post.where("updated_at < ?", Time.now - 1.day)
    cache_fragment(object_cache_key: query.cache_key) { query.some_process }
  end
end
```

### User-provided cache key (custom key)

In most cases you want your cache key to depend on the resolved object (say, `ActiveRecord` model). You can do that by passing an argument to the `#cache_fragment` method in a similar way to Rails views [`#cache` method](https://guides.rubyonrails.org/caching_with_rails.html#fragment-caching):

```ruby
def post(id:)
  post = Post.find(id)
  cache_fragment(post) { post }
end
```

You can pass arrays as well to build a compound cache key:

```ruby
def post(id:)
  post = Post.find(id)
  cache_fragment([post, current_account]) { post }
end
```

You can omit the block if its return value is the same as the cached object:

```ruby
# the following line
cache_fragment(post)
# is the same as
cache_fragment(post) { post }
```

Using literals: Even when using a same string for all queries, the cache changes per argument and per selection set (because of the query_key).

```ruby
def post(id:)
  cache_fragment("find_post") { Post.find(id) }
end
```

Combining with options:

```ruby
def post(id:)
  cache_fragment("find_post", expires_in: 5.minutes) { Post.find(id) }
end
```

Dynamic cache key:

```ruby
def post(id:)
  last_updated_at = Post.select(:updated_at).find_by(id: id)&.updated_at
  cache_fragment(last_updated_at, expires_in: 5.minutes) { Post.find(id) }
end
```

Note the usage of `.select(:updated_at)` at the cache key field to make this verifying query as fastest and light as possible.

You can also add touch options for the belongs_to association e.g author's `belongs_to: :post` to have a `touch: true`.
So that it invalidates the Post when the author is updated.

When using `cache_fragment:` option, it's only possible to use the resolved value as a cache key by setting:

```ruby
field :post, PostType, null: true, cache_fragment: {cache_key: :object} do
  argument :id, ID, required: true
end

# this is equal to
def post(id:)
  cache_fragment(Post.find(id))
end
```

Also, you can pass `:value` to the `cache_key:` argument to use the returned value to build a key:

```ruby
field :post, PostType, null: true, cache_fragment: {cache_key: :value} do
  argument :id, ID, required: true
end

# this is equal to
def post(id:)
  post = Post.find(id)
  cache_fragment(post) { post }
end
```

The way cache key part is generated for the passed argument is the following:

- Use `object_cache_key: "some_cache_key"` if passed to `cache_fragment`
- Use `#graphql_cache_key` if implemented.
- Use `#cache_key` (or `#cache_key_with_version` for modern Rails) if implemented.
- Use `self.to_s` for _primitive_ types (strings, symbols, numbers, booleans).
- Raise `ArgumentError` if none of the above.

### Context cache key

By default, we do not take context into account when calculating cache keys. That's because caching is more efficient when it's _context-free_.

However, if you want some fields to be cached per context, you can do that either by passing context objects directly to the `#cache_fragment` method (see above) or by adding a `context_key` option to `cache_fragment:`.

For instance, imagine a query that allows the current user's social profiles:

```gql
query {
  socialProfiles {
    provider
    id
  }
}
```

You can cache the result using the context (`context[:user]`) as a cache key:

```ruby
class QueryType < BaseObject
  field :social_profiles, [SocialProfileType], null: false, cache_fragment: {context_key: :user}

  def social_profiles
    context[:user].social_profiles
  end
end
```

This is equal to using `#cache_fragment` the following way:

```ruby
class QueryType < BaseObject
  field :social_profiles, [SocialProfileType], null: false

  def social_profiles
    cache_fragment(context[:user]) { context[:user].social_profiles }
  end
end
```

## Cache storage and options

It's up to your to decide which caching engine to use, all you need is to configure the cache store:

```ruby
GraphQL::FragmentCache.cache_store = MyCacheStore.new
```

Or, in Rails:

```ruby
# config/application.rb (or config/environments/<environment>.rb)
Rails.application.configure do |config|
  # arguments and options are the same as for `config.cache_store`
  config.graphql_fragment_cache.store = :redis_cache_store
end
```

⚠️ Cache store must implement `#read(key)`, `#exist?(key)` and `#write_multi(hash, **options)` or `#write(key, value, **options)` methods.

The gem provides only in-memory store out-of-the-box (`GraphQL::FragmentCache::MemoryStore`). It's used by default.

You can pass store-specific options to `#cache_fragment` or `cache_fragment:`. For example, to set expiration (assuming the store's `#write` method supports `expires_in` option):

```ruby
class PostType < BaseObject
  field :id, ID, null: false
  field :title, String, null: false, cache_fragment: {expires_in: 5.minutes}
end

class QueryType < BaseObject
  field :post, PostType, null: true do
    argument :id, ID, required: true
  end

  def post(id:)
    cache_fragment(expires_in: 5.minutes) { Post.find(id) }
  end
end
```

## How to use `#cache_fragment` in extensions (and other places where context is not available)

If you want to call `#cache_fragment` from places other that fields or resolvers, you'll need to pass `context` explicitly and turn on `raw_value` support. For instance, let's take a look at this extension:

```ruby
class Types::QueryType < Types::BaseObject
  class CurrentMomentExtension < GraphQL::Schema::FieldExtension
    # turning on cache_fragment support
    include GraphQL::FragmentCache::ObjectHelpers

    def resolve(object:, arguments:, context:)
      # context is passed explicitly
      cache_fragment(context: context) do
        result = yield(object, arguments)
        "#{result} (at #{Time.now})"
      end
    end
  end

  field :event, String, null: false, extensions: [CurrentMomentExtension]

  def event
    "something happened"
  end
end
```

With this approach you can use `#cache_fragment` in any place you have an access to the `context`. When context is not available, the error `cannot find context, please pass it explicitly` will be thrown.

## In–memory fragments

If you have a fragment that accessed from multiple times (e.g., if you have a list of items that belong to the same owner, and owner is cached), you can avoid multiple cache reads by using `:keep_in_context` option:

```ruby
class QueryType < BaseObject
  field :post, PostType, null: true do
    argument :id, ID, required: true
  end

  def post(id:)
    cache_fragment(keep_in_context: true, expires_in: 5.minutes) { Post.find(id) }
  end
end
```

This can reduce a number of cache calls but _increase_ memory usage, because the value returned from cache will be kept in the GraphQL context until the query is fully resolved.

## Limitations

1. `Schema#execute`, [graphql-batch](https://github.com/Shopify/graphql-batch) and _graphql-ruby-fragment_cache_ do not [play well](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/issues/45) together. The problem appears when `cache_fragment` is _inside_ the `.then` block:

```ruby
def cached_author_inside_batch
  AuthorLoader.load(object).then do |author|
    cache_fragment(author, context: context)
  end
end
```

The problem is that context is not [properly populated](https://github.com/rmosolgo/graphql-ruby/issues/3397) inside the block (the gem uses `:current_path` to build the cache key). There are two possible workarounds: use [dataloaders](https://graphql-ruby.org/dataloader/overview.html) or manage `:current_path` manually:

```ruby
def cached_author_inside_batch
  outer_path = context.namespace(:interpreter)[:current_path]

  AuthorLoader.load(object).then do |author|
    context.namespace(:interpreter)[:current_path] = outer_path
    cache_fragment(author, context: context)
  end
end
```

2. Caching does not work for Union types, because of the `Lookahead` implementation: it requires the exact type to be passed to the `selection` method (you can find the [discussion](https://github.com/rmosolgo/graphql-ruby/pull/3007) here). This method is used for cache key building, and I haven't found a workaround yet ([PR in progress](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/30)). If you get `Failed to look ahead the field` error — please pass `query_cache_key` explicitly:

```ruby
field :cached_avatar_url, String, null: false

def cached_avatar_url
  cache_fragment(query_cache_key: "post_avatar_url(#{object.id})") { object.avatar_url }
end
```

## Credits

Based on the original [gist](https://gist.github.com/palkan/faad9f6ff1db16fcdb1c071ec50e4190) by [@palkan](https://github.com/palkan) and [@ssnickolay](https://github.com/ssnickolay).

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
