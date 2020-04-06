# frozen_string_literal: true

require "spec_helper"
require "json"
require "digest"

RSpec.describe GraphQL::FragmentCache::Object::ObjectPatch do
  let(:schema) { build_schema(query_type) }
  let(:expires_in) { nil }
  let(:variables) { {id: 1, expiresIn: expires_in} }
  let(:context) { {} }

  let(:post_spy) do
    spy("Post").tap do |spy|
      allow(spy).to receive(:id).and_return("1")
      allow(spy).to receive(:title).and_return("Post title")
    end
  end

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

  before do
    allow(TestModels::Post).to receive(:find).with("1") { post_spy }
  end

  context "when block is passed" do
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

    include_context "check used key"

    it "evaluates post fields" do
      schema.execute(query, variables: variables)

      expect(post_spy).to have_received(:id)
      expect(post_spy).to have_received(:title)
    end

    context "when :ex is passed" do
      let(:expires_in) { 60 }
      let(:schema) { build_schema(query_type) }

      include_context "check used key", expires_in: 60
    end
  end

  context "when object is passed" do
    let(:query_type) do
      Class.new(TestTypes::BaseType) do
        graphql_name "QueryType"

        field :post, TestTypes::PostType, null: true do
          argument :id, GraphQL::Types::ID, required: true
          argument :expires_in, GraphQL::Types::Int, required: false
        end

        def post(id:, expires_in: nil)
          post = TestModels::Post.find(id)
          cache_fragment(post, expires_in: expires_in)
        end
      end
    end

    include_context "check used key"

    it "evaluates post fields" do
      schema.execute(query, variables: variables)

      expect(post_spy).to have_received(:id)
      expect(post_spy).to have_received(:title)
    end

    context "when :ex is passed" do
      let(:expires_in) { 60 }
      let(:schema) { build_schema(query_type) }

      include_context "check used key", expires_in: 60
    end
  end

  context "when block and object are passed" do
    let(:query_type) do
      Class.new(TestTypes::BaseType) do
        graphql_name "QueryType"

        field :post, TestTypes::PostType, null: true do
          argument :id, GraphQL::Types::ID, required: true
          argument :expires_in, GraphQL::Types::Int, required: false
        end

        def post(id:, expires_in: nil)
          post = TestModels::Post.find(id)
          cache_fragment(post, expires_in: expires_in) { TestModels::Post.find(id) }
        end
      end
    end

    it "raises ArgumentError" do
      expect { schema.execute(query, variables: variables) }.to raise_error(
        ArgumentError,
        "both object and block could not be passed to cache_fragment"
      )
    end
  end
end
