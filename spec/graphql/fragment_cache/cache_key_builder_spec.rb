# frozen_string_literal: true

require "spec_helper"

describe GraphQL::FragmentCache::CacheKeyBuilder do
  let(:schema) do
    build_schema do
      query(Types::Query)
    end
  end

  let(:query) do
    <<~GQL
      query GetPost($id: ID!) {
        cachedPost(id: $id) {
          id
          title
        }
      }
    GQL
  end

  let(:id) { 1 }
  let(:variables) { {id: id} }
  let(:path) { ["cachedPost"] }

  let(:post) { Post.find(42) }

  let(:object) { nil }
  let(:context) { {} }
  let(:query_obj) { GraphQL::Query.new(schema, query, variables: variables, context: context) }

  subject { described_class.call(object: object, query: query_obj, path: path) }

  # Make cache keys raw for easier debugging
  let(:schema_cache_key) { "schema_key" }
  before do
    allow(schema).to receive(:schema_cache_key) { schema_cache_key }
    allow(Digest::SHA1).to receive(:hexdigest) { |val| val }
  end

  specify { is_expected.to eq "schema_key/cachedPost(id:#{id})[id.title]" }

  context "when cached field has nested selections" do
    let(:query) do
      <<~GQL
        query GetPost($id: ID!) {
          cachedPost(id: $id) {
            id
            title
            author {
              id
              name
            }
          }
        }
      GQL
    end


    specify { is_expected.to eq "schema_key/cachedPost(id:#{id})[id.title.author[id.name]]" }
  end

  context "when argument is input" do
    let(:query) do
      <<~GQL
        query GetPostByInput($inputWithId: PostInput!) {
          cachedPostByInput(inputWithId: $inputWithId) {
            id
            title
            author {
              id
              name
            }
          }
        }
      GQL
    end

    let(:path) { ["cachedPostByInput"] }
    let(:variables) { {inputWithId: {id: id, intArg: 42}} }

    specify { is_expected.to eq "schema_key/cachedPostByInput(input_with_id:{id:#{id},int_arg:42})[id.title.author[id.name]]" }

    context "when argument is complext input" do
      let(:query) do
        <<~GQL
          query GetPostByComplexInput($complexPostInput: ComplexPostInput!) {
            cachedPostByComplexInput(complexPostInput: $complexPostInput) {
              id
              title
              author {
                id
                name
              }
            }
          }
        GQL
      end

      let(:path) { ["cachedPostByComplexInput"] }

      let(:variables) { {complexPostInput: {stringArg: "woo", inputWithId: {id: id, intArg: 42}}} }

      specify { is_expected.to eq "schema_key/cachedPostByComplexInput(complex_post_input:{input_with_id:{id:#{id},int_arg:42},string_arg:woo})[id.title.author[id.name]]" }
    end
  end

  context "when cached cached field is nested" do
    let(:path) { ["post", "cachedAuthor"] }

    let(:query) do
      <<~GQL
        query GetPost($id: ID!) {
          post(id: $id) {
            id
            title
            cachedAuthor {
              id
              name
            }
          }
        }
      GQL
    end

    specify { is_expected.to eq "schema_key/post(id:#{id})/cachedAuthor[id.name]" }
  end

  context "when fragment is used" do
    let(:query) do
      <<~GQL
        fragment PostFragment on PostType {
          id
          title
          author {
            id
            name
          }
        }

        query GetPost($id: ID!) {
          cachedPost(id: $id) {
            ...PostFragment
          }
        }
      GQL
    end


    specify { is_expected.to eq "schema_key/cachedPost(id:#{id})[id.title.author[id.name]]" }

    context "when nested fragment is used" do
      let(:path) { ["post", "cachedAuthor"] }

      let(:query) do
        <<~GQL
          fragment UserFragment on UserType {
            id
            name
          }

          query GetPost($id: ID!) {
            post(id: $id) {
              id
              title
              cachedAuthor {
                ...UserFragment
              }
            }
          }
        GQL
      end

      specify { is_expected.to eq "schema_key/post(id:#{id})/cachedAuthor[id.name]" }
    end
  end

  context "when object is passed and responds to #cache_key" do
    let(:object) { post }

    specify { is_expected.to eq "schema_key/cachedPost(id:#{id})[id.title]/#{post.cache_key}" }
  end

  context "when object is passed and responds to #graphql_cache_key" do
    before do
      post.singleton_class.define_method(:graphql_cache_key) { "super-cache" }
    end

    let(:object) { post }

    specify { is_expected.to eq "schema_key/cachedPost(id:#{id})[id.title]/super-cache" }
  end

  context "when object is passed deosn't respond to #cache_key neither #graphql_cache_key" do
    let(:object) { post.author }

    it "fallbacks to #to_s" do
      is_expected.to eq "schema_key/cachedPost(id:#{id})[id.title]/#{post.author}"
    end
  end

  context "when array is passed as object" do
    let(:object) { [post, :custom, 99] }

    specify { is_expected.to eq "schema_key/cachedPost(id:#{id})[id.title]/#{post.cache_key}/custom/99" }
  end

  context "when scalar field is cached inside the collection" do
    let(:query) do
      <<~GQL
        query GetPosts {
          posts {
            id
            cachedTitle
          }
        }
      GQL
    end
    let(:path) { ["posts", 0, "cachedTitle"] }

    specify { is_expected.to eq "schema_key/posts/0/cachedTitle[]" }
  end

  context "when query has fragment" do
    let(:query) do
      <<~GQL
        fragment PostFragment on PostType {
          id
          author: cachedAuthor {
            name
          }
        }

        query getPost($id: ID!) {
          post(id: $id) {
            ...PostFragment
          }
        }
      GQL
    end

    let(:path) { ["post", "author"] }

    specify { is_expected.to eq "schema_key/post(id:1)/cachedAuthor[name]" }
  end

  context "when query has inline fragment" do
    let(:query) do
      <<~GQL
        query getPost($id: ID!) {
          post(id: $id) {
            ...on PostType {
              id
              author: cachedAuthor {
                name
              }
            }
          }
        }
      GQL
    end

    let(:path) { ["post", "author"] }

    specify { is_expected.to eq "schema_key/post(id:1)/cachedAuthor[name]" }
  end

  context "when query has union type" do
    let(:path) { ["lastActivity", "cachedAvatarUrl"] }

    let(:query) do
      <<~GQL
        query getLastActivity {
          lastActivity {
            ...on PostType {
              id
              cachedAvatarUrl
            }
            ...on UserType {
              id
              cachedAvatarUrl
            }
          }
        }
      GQL
    end

    specify { is_expected.to eq "schema_key/lastActivity/cachedAvatarUrl[]" }

    context "when array of union typed objects is returned" do
      let(:query) do
        <<~GQL
          query getFeed {
            feed {
              ...on PostType {
                id
                cachedAvatarUrl
              }
              ...on UserType {
                id
                cachedAvatarUrl
              }
            }
          }
        GQL
      end

      let(:path) { ["feed", 0, "cachedAvatarUrl"] }

      specify { is_expected.to eq "schema_key/feed/0/cachedAvatarUrl[]" }

      context "when cached field has alias" do
        let(:query) do
          <<~GQL
            query getFeed {
              feed {
                ...on PostType {
                  id
                  avatarUrl: cachedAvatarUrl
                }
                ...on UserType {
                  id
                  avatarUrl: cachedAvatarUrl
                }
              }
            }
          GQL
        end

        let(:path) { ["feed", 0, "avatarUrl"] }

        specify { is_expected.to eq "schema_key/feed/0/cachedAvatarUrl[]" }
      end
    end
  end
end
