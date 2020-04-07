# frozen_string_literal: true

require "rails_helper"

describe GraphQL::FragmentCache::Railtie do
  describe "config.graphql_fragment_cache.store=" do
    around do |ex|
      old_store = GraphQL::FragmentCache.cache_store
      ex.run
      GraphQL::FragmentCache.cache_store = old_store
    end

    it "supports Rails API" do
      Rails.application.config.graphql_fragment_cache.store = :memory_store, {max_size: 10.megabytes}

      expect(GraphQL::FragmentCache.cache_store).to be_a(ActiveSupport::Cache::MemoryStore)
      expect(GraphQL::FragmentCache.cache_store.options[:max_size]).to eq 10.megabytes
    end
  end
end
