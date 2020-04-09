# frozen_string_literal: true

require "spec_helper"

describe "cache_fragment: option" do
  let(:cache_fragment) { true }

  let(:schema) do
    cache_fragment_options = cache_fragment

    build_schema do
      query(
        Class.new(Types::Query) {
          field :post, Types::Post, null: true, cache_fragment: cache_fragment_options do
            argument :id, GraphQL::Types::ID, required: true
          end
        }
      )
    end
  end

  let(:id) { 1 }
  let(:variables) { {id: id} }

  let(:query) do
    <<~GQL
      query getPost($id: ID!){
        post(id: $id) {
          id
          title
        }
      }
    GQL
  end

  let(:post) { Post.create(id: id, title: "option test") }

  before do
    # prepare post
    post
    # warmup cache
    execute_query
    # make object dirty
    post.title = "new option test"
  end

  context "when cache_fragment option is true" do
    it "returns cached fragment" do
      expect(execute_query.dig("data", "post")).to eq({
        "id" => "1",
        "title" => "option test"
      })
    end
  end

  context "when cache_fragment option contains key settings" do
    let(:cache_fragment) { {query_cache_key: "custom"} }

    it "returns the same cache fragment for a different query when query_cache_key is constant" do
      variables[:id] = 2

      expect(execute_query.dig("data", "post")).to eq({
        "id" => "1",
        "title" => "option test"
      })
    end
  end

  context "when :expires_in is passed" do
    let(:cache_fragment) { {expires_in: 60} }

    it "invalidate cache after the specifed time" do
      expect(execute_query.dig("data", "post")).to eq({
        "id" => "1",
        "title" => "option test"
      })

      Timecop.travel(Time.now + 61)

      expect(execute_query.dig("data", "post")).to eq({
        "id" => "1",
        "title" => "new option test"
      })

      post.title = "yet another expiration?"

      expect(execute_query.dig("data", "post")).to eq({
        "id" => "1",
        "title" => "new option test"
      })
    end
  end

  context "with context_key" do
    let(:user) { CacheableUser.new(id: 1, name: "admin") }

    context "with single context_key" do
      let(:cache_fragment) { {context_key: :user} }
      let(:context) { {user: user} }

      it "returns invalidates cached fragment when context is changed" do
        expect(execute_query.dig("data", "post")).to eq({
          "id" => "1",
          "title" => "option test"
        })

        context[:user] = CacheableUser.new(id: 2, name: "another-admin")
        expect(execute_query.dig("data", "post")).to eq({
          "id" => "1",
          "title" => "new option test"
        })
      end
    end

    context "with multiple context keys" do
      let(:cache_fragment) { {context_key: [:user, :account_id]} }
      let(:context) { {user: user, account_id: 26} }

      it "returns invalidates cached fragment when either of contexts is changed" do
        expect(execute_query.dig("data", "post")).to eq({
          "id" => "1",
          "title" => "option test"
        })

        context[:user] = CacheableUser.new(id: 2, name: "another-admin")
        expect(execute_query.dig("data", "post")).to eq({
          "id" => "1",
          "title" => "new option test"
        })

        post.title = "yet another test"
        expect(execute_query.dig("data", "post")).to eq({
          "id" => "1",
          "title" => "new option test"
        })

        context[:account_id] = 27
        expect(execute_query.dig("data", "post")).to eq({
          "id" => "1",
          "title" => "yet another test"
        })
      end
    end
  end

  xcontext "with object_key: true" do
    let(:schema) do
      cache_fragment_options = cache_fragment

      post_type = Class.new(Types::Post) {
        field :cached_author, Types::User, null: true, cache_fragment: cache_fragment_options
      }

      build_schema do
        query(
          Class.new(Types::Query) {
            field :post, post_type, null: true do
              argument :id, GraphQL::Types::ID, required: true
            end
          }
        )
      end
    end

    let(:query) do
      <<~GQL
        query getPost($id: ID!){
          post(id: $id) {
            id
            title
            cachedAuthor {
              name
            }
          }
        }
      GQL
    end

    let(:post) { Post.create(id: id, title: "option test", author: User.new(id: 22, name: "Jack")) }

    let(:cache_fragment) { {object_key: true} }

    it "returns a new version when post.cache_key has changed" do
      post.author.name = "John"
      expect(execute_query.dig("data", "post", "cachedAuthor")).to eq({
        "id" => "22",
        "name" => "Jack"
      })

      # change post title to change the post.cache_key
      post.title = "new option"
      expect(execute_query.dig("data", "post", "cachedAuthor")).to eq({
        "id" => "22",
        "name" => "John"
      })
    end
  end
end
