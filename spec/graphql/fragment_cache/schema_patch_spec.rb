# frozen_string_literal: true

require "spec_helper"

describe GraphQL::FragmentCache::SchemaPatch do
  let(:query_type) do
    Class.new(TestTypes::BaseType) do
      graphql_name "QueryType"

      field :cached_post, TestTypes::PostType, null: true do
        argument :id, GraphQL::Types::ID, required: true
      end

      def cached_post(id:)
        cache_fragment { Post.find(id) }
      end
    end
  end

  let(:schema) { build_schema(query_type) }

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

    let(:user_spy) do
      spy("User").tap do |spy|
        allow(spy).to receive(:id).and_return("2")
        allow(spy).to receive(:name).and_return("User #1")
      end
    end

    let(:post_spy) do
      spy("Post").tap do |spy|
        allow(spy).to receive(:id).and_return("1")
        allow(spy).to receive(:title).and_return("Post title")
        allow(spy).to receive(:author).and_return(user_spy)
      end
    end

    let(:key) do
      build_key(
        schema,
        path_cache_key: ["cachedPost(id:1)"],
        selections_cache_key: {"cachedPost" => %w[id title]}
      )
    end

    before do
      allow(Post).to receive(:find).with("1") { post_spy }
    end

    it "evaluates post fields" do
      schema.execute(query)
      expect(post_spy).to have_received(:id)
      expect(post_spy).to have_received(:title)
    end

    it "caches value in the store" do
      schema.execute(query)

      expect(schema.fragment_cache_store.get(key)).to eq(
        "id" => "1", "title" => "Post title"
      )
    end
  end

  context "when cache is warm" do
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
        schema,
        path_cache_key: ["cachedPost(id:1)"],
        selections_cache_key: {"cachedPost" => %w[id title]}
      )
    end

    let(:cached_post) { {"id" => "1", "title" => "Old cached title"} }

    let(:user_spy) do
      spy("User").tap do |spy|
        allow(spy).to receive(:id).and_return("2")
        allow(spy).to receive(:name).and_return("User #1")
      end
    end

    let(:post_spy) do
      spy("Post").tap do |spy|
        allow(spy).to receive(:id).and_return("1")
        allow(spy).to receive(:title).and_return("New title")
        allow(spy).to receive(:author).and_return(user_spy)
      end
    end

    before do
      schema.fragment_cache_store.set(key, cached_post)

      allow(Post).to receive(:find).with("1") { post_spy }
    end

    it "not evaluates post and user fields" do
      schema.execute(query).inspect

      expect(post_spy).not_to have_received(:id)
      expect(post_spy).not_to have_received(:title)
      expect(post_spy).not_to have_received(:author)

      expect(user_spy).not_to have_received(:id)
      expect(user_spy).not_to have_received(:name)
    end

    it "returns cached value" do
      expect(schema.execute(query)).to eq("data" => {"cachedPost" => cached_post})
    end
  end
end
