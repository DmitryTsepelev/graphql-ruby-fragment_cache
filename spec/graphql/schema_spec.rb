# frozen_string_literal: true

require "spec_helper"

describe GraphQL::Schema do
  describe "#multiplex" do
    let(:schema) { TestSchema }

    let(:id1) { 1 }
    let(:id2) { 2 }

    let!(:post1) { Post.create(id: id1, title: "object test") }
    let!(:post2) { Post.create(id: id2, title: "object test") }

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
  end
end
