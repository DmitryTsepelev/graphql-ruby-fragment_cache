# frozen_string_literal: true

require "rails_helper"

xdescribe GraphQL::FragmentCache::CacheKeyBuilder do
  let(:schema) { TestSchema }

  let(:query) do
    <<~GQL
      query GetPost($id: ID!) {
        cachedPost(id: $id) {
          id
          title
        }
      }
    GQL
  end

  let(:id) { 1 }
  let(:variables) { {id: id} }
  let(:path) { ["cachedPost"] }

  let(:object) { Post.find(42) }
  let(:query_obj) { GraphQL::Query.new(schema, query, variables: variables) }

  # Make cache keys raw for easier debugging
  let(:schema_cache_key) { "schema_key" }
  before do
    allow(schema).to receive(:schema_cache_key) { schema_cache_key }
    allow(Digest::SHA1).to receive(:hexdigest) { |val| val }
  end

  subject { described_class.call(object: object, query: query_obj, path: path) }

  it "uses Cache.expand_cache_key" do
    allow(ActiveSupport::Cache).to receive(:expand_cache_key).with(object) { "as:cache:key" }
    expected_key =
      build_key(
        cache_key: "as:cache:key",
        schema_cache_key: schema_cache_key,
        path_cache_key: ["cachedPost(id:#{id})"],
        selections_cache_key: {"cachedPost" => ["id", "title", "author" => %w[id name]]}
      )

    is_expected.to eq expected_key
  end
end
