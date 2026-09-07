# frozen_string_literal: true

require "spec_helper"

describe "mutations" do
  let(:schema) { TestSchema }

  let(:id) { 1 }
  let(:author) { User.new(id: 1, name: "John") }
  let!(:post) { Post.create(id: id, title: "object test", author: author) }

  subject { schema.execute(query, variables: {id: id}).to_h }

  context "when the mutation response type uses a synchronous cache_fragment" do
    let(:query) do
      <<~GQL
        mutation updatePost($id: ID!) {
          updatePost(id: $id) {
            post {
              cachedTitle
            }
          }
        }
      GQL
    end

    it "executes without raising SystemStackError" do
      expect(subject).to eq(
        {"data" => {"updatePost" => {"post" => {"cachedTitle" => post.title}}}}
      )
    end
  end

  context "when the mutation response type uses cache_fragment on a batched value" do
    let(:query) do
      <<~GQL
        mutation updatePost($id: ID!) {
          updatePost(id: $id) {
            post {
              batchedCachedAuthor {
                name
              }
            }
          }
        }
      GQL
    end

    it "executes without raising SystemStackError" do
      expect(subject).to eq(
        {"data" => {"updatePost" => {"post" => {"batchedCachedAuthor" => {"name" => author.name}}}}}
      )
    end
  end
end
