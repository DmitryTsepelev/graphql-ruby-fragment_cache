# frozen_string_literal: true

require "spec_helper"

RSpec.describe GraphQL::FragmentCache::FieldClassPatch do
  def ensure_generated_key(schema, expected_key)
    expect(schema.fragment_cache_store).to have_received(:set) do |key|
      expect(key).to eq(expected_key)
    end
  end

  let(:cache_fragment) { true }

  let(:query_type_lambda) do
    cache_fragment_options = cache_fragment

    lambda do
      Class.new(GraphQL::Schema::Object) do
        graphql_name "QueryType"

        field :post, PostType, null: true, cache_fragment: cache_fragment_options do
          argument :id, GraphQL::Types::ID, required: true
        end

        def post(id:)
          Post.find(id)
        end
      end
    end
  end

  let(:schema) { build_schema(query_type_lambda) }

  let(:query) do
    <<~GQL
      query {
        post(id: 1) {
          id
          title
        }
      }
    GQL
  end

  before do
    allow(schema.fragment_cache_store).to receive(:set)
  end

  context "when cache_fragment option is true" do
    let(:key) do
      build_key(
        schema,
        path_cache_key: ["post(id:1)"],
        selections_cache_key: { "post" => %w[id title] }
      )
    end

    it "caches field" do
      schema.execute(query)

      ensure_generated_key(schema, key)
    end
  end

  context "when cache_fragment option contains key settings" do
    let(:cache_fragment) do
      { query_cache_key: "custom" }
    end

    let(:key) do
      build_key(
        schema,
        query_cache_key: cache_fragment[:query_cache_key]
      )
    end

    it "caches field" do
      schema.execute(query)

      ensure_generated_key(schema, key)
    end
  end
end
