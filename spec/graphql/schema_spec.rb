# frozen_string_literal: true

require "spec_helper"

describe GraphQL::Schema do
  describe "#multiplex" do
    let(:schema) { TestSchema }

    let(:id1) { 1 }
    let(:id2) { 2 }

    let(:author1) { User.new(id: 1, name: "John") }
    let(:author2) { User.new(id: 2, name: "Max") }

    let!(:post1) { Post.create(id: id1, title: "object test", author: author1) }
    let!(:post2) { Post.create(id: id2, title: "object test", author: author2) }

    let(:query1) do
      <<~GQL
        query getPost1($id: ID!) {
          cachedPost(id: $id) {
            id
            title
          }
        }
      GQL
    end

    let(:query2) do
      <<~GQL
        query getPost2($id: ID!) {
          cachedPost(id: $id) {
            id
            title
          }
        }
      GQL
    end

    let(:queries) do
      [
        {query: query1, variables: {id: id1}},
        {query: query2, variables: {id: id2}}
      ]
    end

    subject { schema.multiplex(queries).map(&:to_h) }

    it "performs multiplex" do
      expect(subject).to eq(
        [
          {"data" => {"cachedPost" => {"id" => post1.id.to_s, "title" => post1.title}}},
          {"data" => {"cachedPost" => {"id" => post2.id.to_s, "title" => post2.title}}}
        ]
      )
    end

    context "when field is cached inside batch" do
      let(:query1) do
        <<~GQL
          query getPost1($id: ID!) {
            post(id: $id) {
              id
              title
              cachedAuthorInsideBatch {
                name
              }
            }
          }
        GQL
      end

      let(:query2) do
        <<~GQL
          query getPost2($id: ID!) {
            post(id: $id) {
              id
              title
              cachedAuthorInsideBatch {
                name
              }
            }
          }
        GQL
      end

      it "executes query using passed context" do
        expect(subject).to eq(
          [
            {"data" => {"post" => {"id" => post1.id.to_s, "title" => post1.title, "cachedAuthorInsideBatch" => {"name" => "John"}}}},
            {"data" => {"post" => {"id" => post2.id.to_s, "title" => post2.title, "cachedAuthorInsideBatch" => {"name" => "Max"}}}}
          ]
        )
      end
    end
  end

  describe "#execute" do
    let(:schema) { TestSchema }

    let(:id) { 1 }

    let(:author) { User.new(id: 1, name: "John") }
    let!(:post) { Post.create(id: id, title: "object test", author: author) }

    let(:query) do
      <<~GQL
        query getPost($id: ID!) {
          post(id: $id) {
            id
            title
            cachedAuthorInsideBatch {
              name
            }
          }
        }
      GQL
    end

    subject { schema.execute(query, variables: {id: id}).to_h }

    context "when field is cached inside batch" do
      it "executes query" do
        expect(subject).to eq(
          {"data" => {
            "post" => {
              "id" => post.id.to_s, "title" => post.title, "cachedAuthorInsideBatch" => {"name" => author.name}
            }
          }}
        )
      end
    end
  end
end
