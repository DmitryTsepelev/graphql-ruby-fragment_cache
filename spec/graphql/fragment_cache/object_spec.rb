# frozen_string_literal: true

require "spec_helper"
require "json"
require "digest"

RSpec.describe GraphQL::FragmentCache::Object do
  let(:query_type) do
    Class.new(GraphQL::Schema::Object) do
      graphql_name "QueryType"

      field :post, PostType, null: true do
        argument :id, GraphQL::Types::ID, required: true
        argument :ex, GraphQL::Types::Int, required: false
      end

      # rubocop:disable Naming/UncommunicativeMethodParamName
      def post(id:, ex: nil)
        cache_fragment(ex: ex) { Post.find(id) }
      end
      # rubocop:enable Naming/UncommunicativeMethodParamName
    end
  end

  let(:schema) { build_schema(query_type) }
  let(:ex) { nil }
  let(:variables) { { id: 1, ex: ex } }
  let(:context) { {} }

  let(:key) do
    build_key(
      schema,
      path_cache_key: ["post(ex:#{ex},id:#{variables[:id]})"],
      selections_cache_key: { "post" => %w[id title] }
    )
  end

  let(:query) do
    <<~GQL
      query GetPost($id: ID!, $ex: Int) {
        post(id: $id, ex: $ex) {
          id
          title
        }
      }
    GQL
  end

  include_context "check used key"

  context "when ex is passed" do
    let(:ex) { 60 }

    include_context "check used key", ex: 60
  end
end
