# frozen_string_literal: true

require "spec_helper"

describe GraphQL::FragmentCache::Cacher do
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

    if GraphQL::FragmentCache.cache_store.respond_to?(:write_multi)
      allow(GraphQL::FragmentCache.cache_store).to receive(:write_multi)
    end
  end

  it "uses #write" do
    execute_query
    expect(GraphQL::FragmentCache.cache_store).to have_received(:write)
  end

  context "when store not supports write_multi" do
    let(:write_multi_store_class) do
      Class.new(GraphQL::FragmentCache::MemoryStore) {
        def write_multi(hash, **options)
          hash.each { |key, value| write(key, value, options) }
        end
      }
    end

    let(:store) { write_multi_store_class.new }

    around do |ex|
      old_store = GraphQL::FragmentCache.cache_store
      GraphQL::FragmentCache.cache_store = store
      ex.run
      GraphQL::FragmentCache.cache_store = old_store
    end

    it "uses #write_multi" do
      execute_query
      expect(GraphQL::FragmentCache.cache_store).to have_received(:write_multi)
    end

    context "when cached fields have different options" do
      let(:schema) do
        build_schema do
          query(
            Class.new(Types::Query) {
              field :post, Types::Post, null: true do
                argument :id, GraphQL::Types::ID, required: true
                argument :cache_key, GraphQL::Types::String, required: true
              end

              define_method(:post) { |id:, cache_key:|
                cache_fragment(query_cache_key: cache_key) { Post.find(id) }
              }
            }
          )
        end
      end

      let(:query) do
        <<~GQL
          query getPost($id: ID!) {
            firstPost: post(id: $id, cacheKey: "1") {
              title
            }

            secondPost: post(id: $id, cacheKey: "2") {
              title
            }
          }
        GQL
      end

      it "uses #write_multi two times with different options" do
        execute_query

        args = []
        expect(GraphQL::FragmentCache.cache_store).to \
          have_received(:write_multi).exactly(2).times do |r, options|
            args << options
          end

        expect(args).to eq([{query_cache_key: "1"}, {query_cache_key: "2"}])
      end
    end
  end
end
