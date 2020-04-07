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

  let(:key) do
    build_key(
      schema_cache_key: schema_cache_key,
      path_cache_key: ["cachedPost(id:#{id})"],
      selections_cache_key: {"cachedPost" => %w[id title]}
    )
  end

  specify { is_expected.to eq key }

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

    let(:key) do
      build_key(
        schema_cache_key: schema_cache_key,
        path_cache_key: ["cachedPost(id:#{id})"],
        selections_cache_key: {"cachedPost" => ["id", "title", "author" => %w[id name]]}
      )
    end

    specify { is_expected.to eq key }
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

    let(:key) do
      build_key(
        schema_cache_key: schema_cache_key,
        path_cache_key: ["post(id:#{id})", "cachedAuthor"],
        selections_cache_key: {"cachedAuthor" => %w[id name]}
      )
    end

    specify { is_expected.to eq key }
  end

  xcontext "when object is passed and responds to #cache_key" do
    let(:object) { post }

    let(:key) do
      build_key(
        schema_cache_key: schema_cache_key,
        path_cache_key: ["cachedPost(id:#{id})"],
        selections_cache_key: {"cachedPost" => %w[id title]}
      )
    end

    specify { is_expected.to eq key }
  end

  xcontext "when object is passed and responds to #graphql_cache_key" do
    before do
      post.singleton_class.define_method(:graphql_cache_key) { "super-cache" }
    end

    let(:object) { post }

    let(:key) do
      build_key(
        cache_key: "super-cache",
        schema_cache_key: schema_cache_key,
        path_cache_key: ["cachedPost(id:#{id})"],
        selections_cache_key: {"cachedPost" => %w[id title]}
      )
    end

    specify { is_expected.to eq key }
  end

  xcontext "when object is passed deosn't respond to #cache_key neither #graphql_cache_key" do
    let(:object) { post.author }

    it "raises ArgumentError" do
      expect { subject }.to raise_error(ArgumentError)
    end
  end

  xcontext "when array is passed as object" do
    let(:object) { [post, :custom] }

    let(:key) do
      build_key(
        cache_key: "#{post.cache_key}/custom",
        schema_cache_key: schema_cache_key,
        path_cache_key: ["cachedPost(id:#{id})"],
        selections_cache_key: {"cachedPost" => %w[id title]}
      )
    end

    specify { is_expected.to eq key }
  end
end
