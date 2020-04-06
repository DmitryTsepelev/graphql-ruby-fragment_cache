# frozen_string_literal: true

require "spec_helper"
require "json"
require "digest"

RSpec.describe GraphQL::FragmentCache::Object do
  let(:query_type) do
    Class.new(TestTypes::BaseType) do
      graphql_name "QueryType"

      field :post, TestTypes::PostType, null: true do
        argument :id, GraphQL::Types::ID, required: true
        argument :expires_in, GraphQL::Types::Int, required: false
      end

      def post(id:, expires_in: nil)
        cache_fragment(expires_in: expires_in) { TestModels::Post.find(id) }
      end
    end
  end

  let(:schema) { build_schema(query_type) }
  let(:expires_in) { nil }
  let(:variables) { {id: 1, expiresIn: expires_in} }
  let(:context) { {} }

  let(:key) do
    build_key(
      schema,
      path_cache_key: ["post(expires_in:#{variables[:expiresIn]},id:#{variables[:id]})"],
      selections_cache_key: {"post" => %w[id title]}
    )
  end

  let(:query) do
    <<~GQL
      query GetPost($id: ID!, $expiresIn: Int) {
        post(id: $id, expiresIn: $expiresIn) {
          id
          title
        }
      }
    GQL
  end

  include_context "check used key"

  context "when expires_in is passed" do
    let(:expires_in) { 60 }

    include_context "check used key", expires_in: 60
  end
end
