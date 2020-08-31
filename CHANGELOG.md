# Change log

## master

## 1.0.3 (2020-08-31)

- [PR#29](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/29) Cache result JSON instead of connection objects ([@DmitryTsepelev][])

## 1.0.2 (2020-08-19)

- [PR#28](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/28) Support #keys method for GraphQL::FragmentCache::MemoryStore instance ([@reabiliti][])

## 1.0.1 (2020-06-17)

- [PR#25](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/25) Support fragments with aliases for CacheKeyBuilder ([@DmitryTsepelev][])

## 1.0.0 (2020-06-13)

- [PR#24](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/24) Add nil caching. **BREAKING CHANGE**: custom cache stores must also implement `#exist?(key)` method ([@DmitryTsepelev][])

## 0.1.7 (2020-06-02)

- [PR#23](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/23) Avoid extra queries after restoring connection from cache ([@DmitryTsepelev][])

## 0.1.6 (2020-05-30)

- [PR#22](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/22) Properly cache entites inside collections ([@DmitryTsepelev][])

## 0.1.5 (2020-04-28)

- [PR#19](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/19) Add connections support ([@DmitryTsepelev][])
- [PR#18](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/18) Support aliases in cache key generation ([@palkan][], [@DmitryTsepelev][])

## 0.1.4 (2020-04-25)

- Fix railtie to set up null store for tests ([@DmitryTsepelev][])

## 0.1.3 (2020-04-24)

- [PR#17](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/17) Properly build cache keys based on input arguments ([@DmitryTsepelev][])

## 0.1.2 (2020-04-24)

- [PR#16](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/16) Railtie turns off caching in test environment ([@DmitryTsepelev][])
- [PR#15](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/15) Avoid extra resolving when resolved_value is not used for building cache key ([@DmitryTsepelev][])

## 0.1.1 (2020-04-15)

- Fix using passed object as a cache key ([@palkan][])

## 0.1.0 (2020-04-14)

- Initial version ([@DmitryTsepelev][], [@palkan][], [@ssnickolay][])

[@DmitryTsepelev]: https://github.com/DmitryTsepelev
[@palkan]: https://github.com/palkan
[@ssnickolay]: https://github.com/ssnickolay
[@reabiliti]: https://github.com/reabiliti
