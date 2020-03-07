# frozen_string_literal: true

require "spec_helper"

RSpec.describe GraphQL::FragmentCache::CacheKeyBuilder do
  before do
    allow(GraphqSchemaWithContextKey.fragment_cache_store).to receive(:set)
  end

  context "when cache is cold" do
    let(:query) do
      <<~GQL
        query {
          cachedPost(id: 1) {
            id
            title
          }
        }
      GQL
    end

    def ensure_generated_key(schema, expected_key)
      expect(schema.fragment_cache_store).to have_received(:set) do |key|
        expect(key).to eq(expected_key)
      end
    end

    it "generates key" do
      GraphqSchemaWithContextKey.execute(query)

      ensure_generated_key(
        GraphqSchemaWithContextKey,
        "#{GraphQL::FragmentCache::DEFAULT_CACHE_NAMESPACE}:" \
        "#{GraphqSchemaWithContextKey.schema_cache_key}:" \
        "cachedPost(id:1):id,title"
      )
    end

    context "when alias is used" do
      # TODO
    end

    context "when fragment has nested selections" do
      let(:query) do
        <<~GQL
          query {
            cachedPost(id: 1) {
              id
              title
              author {
                id
                name
              }
            }
          }
        GQL
      end

      it "caches value in the store" do
        GraphqSchemaWithContextKey.execute(query)

        ensure_generated_key(
          GraphqSchemaWithContextKey,
          "#{GraphQL::FragmentCache::DEFAULT_CACHE_NAMESPACE}:" \
          "#{GraphqSchemaWithContextKey.schema_cache_key}:" \
          "cachedPost(id:1):author{id,name},id,title"
        )
      end
    end

    context "when cached fragment is nested" do
      let(:query) do
        <<~GQL
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
      end

      it "caches value in the store" do
        GraphqSchemaWithContextKey.execute(query)

        ensure_generated_key(
          GraphqSchemaWithContextKey,
          "#{GraphQL::FragmentCache::DEFAULT_CACHE_NAMESPACE}:" \
          "#{GraphqSchemaWithContextKey.schema_cache_key}:" \
          "post(id:1)->cachedAuthor:id,name"
        )
      end
    end

    context "when context_key is configured" do
      let(:context) { { current_user_id: 42 } }

      it "caches value in the store" do
        GraphqSchemaWithContextKey.execute(query, context: context)

        ensure_generated_key(
          GraphqSchemaWithContextKey,
          "#{GraphQL::FragmentCache::DEFAULT_CACHE_NAMESPACE}:" \
          "#{GraphqSchemaWithContextKey.schema_cache_key}:" \
          "cachedPost(id:1):id,title:42"
        )
      end
    end
  end
end
