# frozen_string_literal: true

require "spec_helper"

describe GraphQL::FragmentCache::Schema::Instrumentation do
  let(:schema) { TestSchema }

  let(:id) { 1 }
  let(:variables) { {id: id} }
  let!(:post) { Post.create(id: id, title: "object test") }

  let(:query) do
    <<~GQL
      query getPost($id: ID!) {
        cachedPost(id: $id) {
          id
          title
        }
      }
    GQL
  end

  before do
    allow(GraphQL::FragmentCache.cache_store).to receive(:write)
  end

  it "writes fragment to cache" do
    execute_query
    expect(GraphQL::FragmentCache.cache_store).to have_received(:write)
  end

  context "when query is invalid" do
    let(:query) { "wrong" }

    it "not writes fragment to cache" do
      execute_query
      expect(GraphQL::FragmentCache.cache_store).not_to have_received(:write)
    end
  end

  context "when query has errors" do
    let(:query) do
      <<~GQL
        query getPost($id: ID!, $id2: ID!) {
          validPost: cachedPost(id: $id) {
            id
          }

          postWithError: cachedPost(id: $id2) {
            id
          }
        }
      GQL
    end

    let(:variables) { {id: id, id2: 0} }

    let(:schema) do
      build_schema do
        query(
          Class.new(Types::Query) {
            field :cached_post, Types::Post, null: true do
              argument :id, GraphQL::Types::ID, required: true
            end

            define_method(:cached_post, ->(id:) {
              raise GraphQL::ExecutionError, "error!" if id == "0"

              cache_fragment { Post.find(id) }
            })
          }
        )
      end
    end

    it "writes fragment to cache" do
      execute_query
      expect(GraphQL::FragmentCache.cache_store).to have_received(:write)
    end

    context "when skip_cache_when_query_has_errors is true" do
      around do |ex|
        GraphQL::FragmentCache.skip_cache_when_query_has_errors = true
        ex.run
        GraphQL::FragmentCache.skip_cache_when_query_has_errors = false
      end

      it "not writes fragment to cache" do
        execute_query
        expect(GraphQL::FragmentCache.cache_store).not_to have_received(:write)
      end
    end
  end
end
