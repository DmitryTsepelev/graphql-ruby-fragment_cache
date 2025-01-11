# Change log

## master

- [PR#130](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/130) Dataloader support ([@DmitryTsepelev][])
- [PR#125](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/125) Introduce cache lookup instrumentation hook ([@danielhartnell][])

## 1.20.5 (2024-11-02)

- [PR#120](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/120) Fix warning on ActiveSupport::Cache.format_version ([@Drowze][])

## 1.20.4 (2024-10-05)

- [PR#119](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/119) Fix Rails cache_format_version deprecation ([@noma4i][])

## 1.20.3 (2024-09-06)

- [PR#117](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/117) Deprecate old ruby and gql versions  ([@DmitryTsepelev][])
- [PR#116](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/116) Migrate CompiledQueries instrumentation to tracer ([@DmitryTsepelev][])

## 1.20.2 (2024-06-01)

- [PR#115](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/115) Fix deprecation warning for cache_format_version in Rails 7.1 ([@rince][])

## 1.20.1 (2024-04-03)

- [PR#112](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/112) fix tracer deprecation warnings ([@diegofigueroa][])
- [PR#109](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/109) Remove `Lookahead` patch in modern versions of graphql-ruby ([@DmitryTsepelev][])

## 1.20.0 (2024-03-02)

- [PR#108](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/108) Use trace_with instead of deprecated instrument method  ([@camero2734][])

## 1.19.0 (2023-11-03)

- [PR#104](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/104) Support graphql-ruby 2.1.4 ([@DmitryTsepelev][])

## 1.18.2 (2023-02-21)

- [PR#100](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/100) Fix an error when `path_cache_key` is nil ([@rince][])

## 1.18.1 (2023-01-06)

- [PR#96](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/96) Properly pass arguments to `write_multi` ([@DmitryTsepelev][])

## 1.18.0 (2022-12-28)

- [PR#94](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/94) Ruby 3 support ([@DmitryTsepelev][])

## 1.17.0 (2022-11-09)

- [PR#92](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/92) Make cache keys human-readable ([@jeromedalbert][])

## 1.16.0 (2022-11-06)

- [PR#42](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/42) Raise helpful errors when write or write_multi fails  ([@DmitryTsepelev][])
- [PR#86](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/86) Support passing Procs to `cache_key:` ([@jeromedalbert][])
- [PR#90](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/90) Add option to disable the cache ([@jeromedalbert][])
- [PR#89](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/89) Use a "graphql" cache namespace by default ([@jeromedalbert][])

## 1.15.0 (2022-10-27)

- [PR#43](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/43) Implement `skip_cache_when_query_has_errors` option to skip caching when query was resolved with errors ([@DmitryTsepelev][])

## 1.14.0 (2022-10-26)

- [PR#85](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/85) Support passing Symbols to `if:` and `unless:` ([@palkan][])

- [PR#85](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/85) Fix conditional caching ([@palkan][])

## 1.13.1 (2022-10-12)

- [PR#84](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/84) Fix Renew Cache Read Multi Bug ([@KTSCode][])

## 1.13.0 (2022-09-12)

- [PR#83](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/83) Update Lookahead usage to support graphql-2.0.14 ([@DmitryTsepelev][])

## 1.12.0 (2022-08-05)

- [PR#70](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/70), [PR#82](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/82) Add #read_multi for fragments ([@daukadolt][], [@frostmark][])

## 1.11.0 (2022-02-26)

- [PR#79](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/79) Support graphql-ruby 2.0.0 ([@DmitryTsepelev][])

## 1.10.0 (2022-01-30)

- [PR#77](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/77) Drop Ruby 2.5 support, add Ruby 3.0 ([@DmitryTsepelev][])

## 1.9.1 (2021-11-28)

- [PR#76](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/76) Freeze parser version ([@DmitryTsepelev][])

## 1.9.0 (2021-08-19)

- [PR#71](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/71) Add selection alias to cache keys ([@mretzak][])

## 1.8.0 (2021-05-13)

- [PR#65](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/65) Add default options ([@jeromedalbert][])

## 1.7.0 (2021-04-30)

- [PR#62](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/62) Add a way to force a cache miss ([@jeromedalbert][])
- [PR#61](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/61) Add conditional caching ([@jeromedalbert][])
- [PR#64](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/64) Add a cache namespace ([@jeromedalbert][])
- [PR#63](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/63) Add a configure block notation ([@jeromedalbert][])

## 1.6.0 (2021-03-13)

- [PR#54](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/54) Include arguments in selections_cache_key ([@bbugh][])

## 1.5.1 (2021-03-10)

- [PR#53](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/53) Use thread-safe query result for final_value ([@bbugh][])
- [PR#51](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/51) Do not cache fragments without final value ([@DmitryTsepelev][])

## 1.5.0 (2021-02-20)

- [PR#50](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/50) Add object_cache_key to CacheKeyBuilder ([@bbugh][])

## 1.4.1 (2021-01-21)

- [PR#48](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/48) Support graphql-ruby 1.12 ([@DmitryTsepelev][])

## 1.4.0 (2020-12-03)

- [PR#41](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/41) Add `keep_in_context` option ([@DmitryTsepelev][])

## 1.3.0 (2020-11-25)

- [PR#39](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/39) Implement `path_cache_key` option ([@DmitryTsepelev][])

## 1.2.0 (2020-10-26)

- [PR#37](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/37) Try to use `cache_key_with_version` or `cache_key` with Rails CacheKeyBuilder ([@bbugh][])

## 1.1.0 (2020-10-26)

- [PR#38](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/38) Support caching from other places than field or resolver  ([@DmitryTsepelev][])

## 1.0.5 (2020-10-13)

- [PR#35](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/35) Prefer using `#write_multi` on cache store when possible ([@DmitryTsepelev][])

## 1.0.4 (2020-10-12)

- [PR#34](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/34) Avoid unneded default calculation in CacheKeyBuilder ([@DmitryTsepelev][])
- [PR#31](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache/pull/31) Do not patch Connection#wrap in graphql >= 1.10.5 ([@DmitryTsepelev][])

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
[@bbugh]: https://github.com/bbugh
[@jeromedalbert]: https://github.com/jeromedalbert
[@mretzak]: https://github.com/mretzak
[@daukadolt]: https://github.com/daukadolt
[@frostmark]: https://github.com/frostmark
[@KTSCode]: https://github.com/KTSCode
[@rince]: https://github.com/rince
[@camero2734]: https://github.com/camero2734
[@diegofigueroa]: https://github.com/diegofigueroa
[@noma4i]: https://github.com/noma4i
[@Drowze]: https://github.com/Drowze
[@danielhartnell]: https://github.com/danielhartnell
