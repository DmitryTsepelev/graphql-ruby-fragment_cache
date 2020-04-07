# frozen_string_literal: true

require "spec_helper"

describe "cache_Fragment: option" do
  let(:cache_fragment) { true }

  let(:schema) do
    cache_fragment_options = cache_fragment

    build_schema do
      query(
        Class.new(Types::Query) {
          field :post, Types::Post, null: true, cache_fragment: cache_fragment_options do
            argument :id, GraphQL::Types::ID, required: true
          end
        }
      )
    end
  end

  let(:id) { 1 }
  let(:variables) { {id: id} }

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

  before do
    # warmup cache
    execute_query
    # make object dirty
    post.title = "new option test"
  end

  context "when cache_fragment option is true" do
    it "returns cached fragment" do
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
