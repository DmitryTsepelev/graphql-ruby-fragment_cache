# frozen_string_literal: true

require "spec_helper"

RSpec.describe GraphQL::FragmentCache::FieldClassPatch do
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

  let(:id) { 1 }
  let(:variables) { { id: id } }
  let(:context) { {} }
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

  context "when cache_fragment option is true" do
    let(:key) do
      build_key(
        schema,
        path_cache_key: ["post(id:1)"],
        selections_cache_key: { "post" => %w[id title] }
      )
    end

    include_context "check used key"
  end

  context "when cache_fragment option contains key settings" do
    let(:cache_fragment) { { query_cache_key: "custom" } }

    let(:key) { build_key(schema, query_cache_key: cache_fragment[:query_cache_key]) }

    include_context "check used key"
  end

  context "when :ex is passed" do
    let(:cache_fragment) { { ex: 60 } }

    let(:key) do
      build_key(
        schema,
        path_cache_key: ["post(id:1)"],
        selections_cache_key: { "post" => %w[id title] }
      )
    end

    let(:schema) { build_schema(query_type_lambda) }

    include_context "check used key", ex: 60
  end
end
