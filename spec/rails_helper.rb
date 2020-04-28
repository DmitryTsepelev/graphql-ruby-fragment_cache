# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require "spec_helper"
require "combustion"
require "graphql/fragment_cache/railtie"

GraphQL::FragmentCache.cache_store = GraphQL::FragmentCache::MemoryStore.new

Combustion.initialize! :active_record
