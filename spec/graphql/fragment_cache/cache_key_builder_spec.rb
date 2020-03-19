# frozen_string_literal: true

require "spec_helper"
require "json"
require "digest"

RSpec.describe GraphQL::FragmentCache::CacheKeyBuilder do
  before do
    allow(GraphqSchemaWithContextKey.fragment_cache_store).to receive(:set)
  end

  def ensure_generated_key(schema, expected_key)
    expect(schema.fragment_cache_store).to have_received(:set) do |key|
      expect(key).to eq(expected_key)
    end
  end

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

  let(:key) do
    build_key(
      GraphqSchemaWithContextKey,
      path_cache_key: ["cachedPost(id:1)"],
      selections_cache_key: { "cachedPost" => %w[id title] }
    )
  end

  it "generates key" do
    GraphqSchemaWithContextKey.execute(query)

    ensure_generated_key(GraphqSchemaWithContextKey, key)
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

    let(:key) do
      build_key(
        GraphqSchemaWithContextKey,
        path_cache_key: ["cachedPost(id:1)"],
        selections_cache_key: { "cachedPost" => ["id", "title", "author" => %w[id name]] }
      )
    end

    it "caches value in the store" do
      GraphqSchemaWithContextKey.execute(query)
      ensure_generated_key(GraphqSchemaWithContextKey, key)
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

    let(:key) do
      build_key(
        GraphqSchemaWithContextKey,
        path_cache_key: ["post(id:1)", "cachedAuthor"],
        selections_cache_key: { "cachedAuthor" => %w[id name] }
      )
    end

    it "caches value in the store" do
      GraphqSchemaWithContextKey.execute(query)

      ensure_generated_key(GraphqSchemaWithContextKey, key)
    end
  end

  context "when context_key is configured" do
    let(:context) { { current_user_id: 42 } }

    let(:key) do
      build_key(
        GraphqSchemaWithContextKey,
        path_cache_key: ["cachedPost(id:1)"],
        selections_cache_key: { "cachedPost" => %w[id title] },
        context_cache_key: 42
      )
    end

    it "caches value in the store" do
      GraphqSchemaWithContextKey.execute(query, context: context)

      ensure_generated_key(GraphqSchemaWithContextKey, key)
    end
  end
end
