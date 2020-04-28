# frozen_string_literal: true

require "rails_helper"

describe GraphQL::FragmentCache::ObjectHelpers do
  class TweetType < GraphQL::Schema::Object
    include GraphQL::FragmentCache::Object

    graphql_name "TweetType"

    field :id, ID, null: false
    field :content, String, null: false
  end

  let(:schema) do
    build_schema do
      query(
        Class.new(Types::Query) {
          field :tweets, TweetType.connection_type, null: false, cache_fragment: true

          def tweets(after: nil)
            Tweet.all
          end
        }
      )
    end
  end

  let(:query) do
    <<~GQL
      query getTweets($before: String, $after: String) {
        tweets(before: $before, after: $after) {
          nodes {
            id
            content
          }
          pageInfo {
            startCursor
            endCursor
            hasNextPage
            hasPreviousPage
          }
        }
      }
    GQL
  end

  let(:after) { nil }
  let(:before) { nil }
  let(:variables) { {after: after, before: before} }

  before(:all) do
    Tweet.create(content: "my first tweet")
    Tweet.create(content: "my second tweet")
  end

  before { execute_query }

  it "returns cached fragment" do
    expect(execute_query.dig("data", "tweets")).to eq(
      "nodes" => [
        {"id" => "1", "content" => "my first tweet"},
        {"id" => "2", "content" => "my second tweet"}
      ],
      "pageInfo" => {
        "startCursor" => schema.cursor_encoder.encode("1"),
        "endCursor" => schema.cursor_encoder.encode("2"),
        "hasPreviousPage" => false,
        "hasNextPage" => false
      },
    )
  end

  it "not calls resolver method" do
    allow(::Tweet).to receive(:all).and_call_original
    execute_query
    expect(::Tweet).not_to have_received(:all)
  end

  context "when after is passed" do
    let(:after) { schema.cursor_encoder.encode("1") }

    it "returns cached fragment" do
      expect(execute_query.dig("data", "tweets")).to eq(
        "nodes" => [
          {"id" => "2", "content" => "my second tweet"}
        ],
        "pageInfo" => {
          "startCursor" => schema.cursor_encoder.encode("2"),
          "endCursor" => schema.cursor_encoder.encode("2"),
          "hasPreviousPage" => true,
          "hasNextPage" => false
        },
      )
    end

    it "not calls resolver method" do
      allow(::Tweet).to receive(:all).and_call_original
      execute_query
      expect(::Tweet).not_to have_received(:all)
    end
  end

  context "when before is passed" do
    let(:before) { schema.cursor_encoder.encode("2") }

    it "returns cached fragment" do
      expect(execute_query.dig("data", "tweets")).to eq(
        "nodes" => [
          {"id" => "1", "content" => "my first tweet"}
        ],
        "pageInfo" => {
          "startCursor" => schema.cursor_encoder.encode("1"),
          "endCursor" => schema.cursor_encoder.encode("1"),
          "hasPreviousPage" => false,
          "hasNextPage" => true
        },
      )
    end

    it "not calls resolver method" do
      allow(::Tweet).to receive(:all).and_call_original
      execute_query
      expect(::Tweet).not_to have_received(:all)
    end
  end
end
