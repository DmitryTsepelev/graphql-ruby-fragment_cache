# frozen_string_literal: true

require "spec_helper"

describe GraphQL::FragmentCache::CacheKeyBuilder do
  let(:schema) do
    build_schema do
      query(Types::Query)
    end
  end

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

  let(:post) { Post.find(42) }

  let(:object) { nil }
  let(:query_obj) { GraphQL::Query.new(schema, query, variables: variables) }

  subject { described_class.call(object: object, query: query_obj, path: path) }

  # Make cache keys raw for easier debugging
  let(:schema_cache_key) { "schema_key" }
  before do
    allow(schema).to receive(:schema_cache_key) { schema_cache_key }
    allow(Digest::SHA1).to receive(:hexdigest) { |val| val }
  end

  specify { is_expected.to eq "schema_key/cachedPost(id:#{id})[id.title]" }

  context "when alias is used"

  context "when fragment has nested selections" do
    let(:query) do
      <<~GQL
        query GetPost($id: ID!) {
          cachedPost(id: $id) {
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

    specify { is_expected.to eq "schema_key/cachedPost(id:#{id})[id.title.author[id.name]]" }
  end

  context "when cached fragment is nested" do
    let(:path) { ["post", "cachedAuthor"] }

    let(:query) do
      <<~GQL
        query GetPost($id: ID!) {
          post(id: $id) {
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

    specify { is_expected.to eq "schema_key/post(id:#{id})/cachedAuthor[id.name]" }
  end

  context "when object is passed and responds to #cache_key" do
    let(:object) { post }

    specify { is_expected.to eq "schema_key/cachedPost(id:#{id})[id.title]/#{post.cache_key}" }
  end

  context "when object is passed and responds to #graphql_cache_key" do
    before do
      post.singleton_class.define_method(:graphql_cache_key) { "super-cache" }
    end

    let(:object) { post }

    specify { is_expected.to eq "schema_key/cachedPost(id:#{id})[id.title]/super-cache" }
  end

  context "when object is passed deosn't respond to #cache_key neither #graphql_cache_key" do
    let(:object) { post.author }

    it "fallbacks to #to_s" do
      is_expected.to eq "schema_key/cachedPost(id:#{id})[id.title]/#{post.author}"
    end
  end

  context "when array is passed as object" do
    let(:object) { [post, :custom, 99] }

    specify { is_expected.to eq "schema_key/cachedPost(id:#{id})[id.title]/#{post.cache_key}/custom/99" }
  end
end
