# frozen_string_literal: true

require "spec_helper"

describe GraphQL::FragmentCache::Object::FieldClassPatch do
  include_context "graphql"

  let(:cache_fragment) { true }

  let(:query_type) do
    cache_fragment_options = cache_fragment

    Class.new(TestTypes::BaseType) do
      graphql_name "QueryType"

      field :post, TestTypes::PostType, null: true, cache_fragment: cache_fragment_options do
        argument :id, GraphQL::Types::ID, required: true
      end

      def post(id:)
        Post.find(id)
      end
    end
  end

  let(:id) { 1 }
  let(:variables) { {id: id} }
  let(:context) { {} }
  let(:schema) { build_schema(query_type) }

  let(:query) do
    <<~GQL
      query getPost($id: ID!){
        post(id: $id) {
          id
          title
        }
      }
    GQL
  end

  let!(:post) { Post.create(id: id, title: "option test") }

  # warmup cache
  before { execute_query }

  context "when cache_fragment option is true" do
    it "returns cached fragment" do
      post.title = "new option test"

      expect(execute_query.dig("data", "post")).to eq({
        "id" => "1",
        "title" => "option test"
      })
    end
  end

  context "when cache_fragment option contains key settings" do
    let(:cache_fragment) { {query_cache_key: "custom"} }

    it "returns the same cache fragment for a different query when query_cache_key is constant" do
      variables[:id] = 2

      expect(execute_query.dig("data", "post")).to eq({
        "id" => "1",
        "title" => "option test"
      })
    end
  end

  context "when :expires_in is passed" do
    let(:cache_fragment) { {expires_in: 60} }

    it "invalidate cache after the specifed time" do
      post.title = "new option test"

      expect(execute_query.dig("data", "post")).to eq({
        "id" => "1",
        "title" => "option test"
      })

      Timecop.travel(Time.now + 61)

      expect(execute_query.dig("data", "post")).to eq({
        "id" => "1",
        "title" => "new option test"
      })

      post.title = "yet another expiration?"

      expect(execute_query.dig("data", "post")).to eq({
        "id" => "1",
        "title" => "new option test"
      })
    end
  end
end
