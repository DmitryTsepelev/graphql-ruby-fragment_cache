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
    allow(GraphQL::FragmentCache.cache_store).to receive(:write).and_call_original

    if GraphQL::FragmentCache.cache_store.respond_to?(:write_multi)
      allow(GraphQL::FragmentCache.cache_store).to receive(:write_multi).and_call_original
    end
  end

  it "uses #write" do
    execute_query
    expect(GraphQL::FragmentCache.cache_store).to have_received(:write)
  end

  context "when store not supports write_multi" do
    let(:write_multi_store_class) do
      Class.new(GraphQL::FragmentCache::MemoryStore) {
        def write_multi(hash, options)
          hash.each { |key, value| write(key, value, options) }
        end
      }
    end

    let(:store) { write_multi_store_class.new }

    before do
      allow(store).to receive(:write_multi).and_call_original
      GraphQL::FragmentCache.cache_store = store
    end

    it "uses #write_multi" do
      execute_query
      expect(GraphQL::FragmentCache.cache_store).to have_received(:write_multi)
    end

    context "when store raises error" do
      let(:write_with_error_store_class) do
        Class.new(GraphQL::FragmentCache::MemoryStore) {
          def write_multi(hash, options)
            raise StandardError, "something went wrong"
          end
        }
      end

      let(:store) { write_with_error_store_class.new }

      it "raises error" do
        expect { execute_query }.to raise_error do |error|
          expect(error).to be_a(GraphQL::FragmentCache::WriteMultiError)
          expect(error.message).to eq("something went wrong")
          expect(error.values).not_to be_nil
          expect(error.original_error).not_to be_nil
        end
      end
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

      context "when different options exist, but should be excluded" do
        let(:schema) do
          build_schema do
            query(
              Class.new(Types::Query) {
                field :post, Types::Post, null: true do
                  argument :id, GraphQL::Types::ID, required: true
                  argument :cache_key, GraphQL::Types::String, required: true
                end

                define_method(:post) { |id:, cache_key:|
                  cache_fragment(cache_key: {exclude_arguments: [:cache_key]}) { Post.find(id) }
                }
              }
            )
          end
        end

        it "uses #write_multi ony one time time" do
          execute_query
          expect(GraphQL::FragmentCache.cache_store).to have_received(:write_multi).once
        end
      end
    end
  end

  context "when store raises error" do
    let(:write_with_error_store_class) do
      Class.new(GraphQL::FragmentCache::MemoryStore) {
        def write(key, value, options)
          raise StandardError, "something went wrong"
        end
      }
    end

    let(:store) { write_with_error_store_class.new }

    before do
      GraphQL::FragmentCache.cache_store = store
    end

    it "raises error" do
      expect { execute_query }.to raise_error do |error|
        expect(error).to be_a(GraphQL::FragmentCache::WriteError)
        expect(error.message).to eq("something went wrong")
        expect(error.key).not_to be_nil
        expect(error.value).not_to be_nil
        expect(error.original_error).not_to be_nil
      end
    end
  end
end
