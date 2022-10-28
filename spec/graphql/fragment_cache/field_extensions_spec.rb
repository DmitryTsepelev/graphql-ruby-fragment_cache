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

    it "not calls resolver method" do
      allow(::Post).to receive(:find).and_call_original
      execute_query
      expect(::Post).not_to have_received(:find)
    end
  end

  context "when cache_fragment option contains query_cache_key" do
    let(:cache_fragment) { {query_cache_key: "custom"} }

    it "returns the same cache fragment for a different query when query_cache_key is constant" do
      variables[:id] = 2

      expect(execute_query.dig("data", "post")).to eq({
        "id" => "1",
        "title" => "option test"
      })
    end
  end

  context "when cache_fragment option contains path_cache_key" do
    let(:cache_fragment) { {path_cache_key: "custom"} }

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

  context "when :cache_key is provided" do
    context "when :cache_key is the special :value Symbol" do
      let(:schema) do
        build_schema do
          query(
            Class.new(Types::Query) {
              field :post, Types::Post, null: true, cache_fragment: {cache_key: :value} do
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
            }
          }
        GQL
      end

      let(:post) { Post.create(id: id, title: "option test") }

      it "returns a new version of post when post.cache_key has changed" do
        expect(execute_query.dig("data", "post")).to eq({
          "id" => "1",
          "title" => "new option test"
        })

        post.title = "new option"
        expect(execute_query.dig("data", "post")).to eq({
          "id" => "1",
          "title" => "new option"
        })
      end

      it "calls resolver method" do
        allow(::Post).to receive(:find).and_call_original
        execute_query
        expect(::Post).to have_received(:find).once
      end
    end

    context "when :cache_key is a Symbol that is not :value" do
      let(:schema) do
        post_type = Class.new(Types::Post) {
          graphql_name "PostWithCachedAuthor"

          field :cached_author, Types::User, null: true, cache_fragment: {cache_key: :object}

          def cached_author
            object.author
          end
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
                id
                name
              }
            }
          }
        GQL
      end

      let(:post) { Post.create(id: id, title: "option test", author: User.new(id: 22, name: "Jack")) }

      it "returns a new version of author when post.cache_key has changed" do
        # re-warmup cache
        execute_query

        post.author.name = "John"
        expect(execute_query.dig("data", "post", "cachedAuthor")).to eq({
          "id" => "22",
          "name" => "Jack"
        })

        post.title = "new option"
        expect(execute_query.dig("data", "post", "cachedAuthor")).to eq({
          "id" => "22",
          "name" => "John"
        })
      end

      it "calls resolver method" do
        allow(::Post).to receive(:find).and_call_original
        execute_query
        expect(::Post).to have_received(:find).once
      end
    end

    context "when :cache_key is a Proc" do
      let(:schema) do
        post_type = Class.new(Types::Post) {
          graphql_name "PostWithCachedAuthor"

          field :cached_author, Types::User, null: true, cache_fragment: {cache_key: -> { object }}

          def cached_author
            object.author
          end
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
                id
                name
              }
            }
          }
        GQL
      end

      let(:post) { Post.create(id: id, title: "option test", author: User.new(id: 22, name: "Jack")) }

      it "returns a new version of author when post.cache_key has changed" do
        # re-warmup cache
        execute_query

        post.author.name = "John"
        expect(execute_query.dig("data", "post", "cachedAuthor")).to eq({
          "id" => "22",
          "name" => "Jack"
        })

        post.title = "new option"
        expect(execute_query.dig("data", "post", "cachedAuthor")).to eq({
          "id" => "22",
          "name" => "John"
        })
      end

      it "calls resolver method" do
        allow(::Post).to receive(:find).and_call_original
        execute_query
        expect(::Post).to have_received(:find).once
      end
    end
  end

  context "when :if is provided" do
    let(:context) { {current_user: User.new(id: "1", name: "some-user")} }
    let(:cache_fragment) { {if: -> { context[:current_user] }} }

    specify do
      # returns cached result when if evaluates to true
      expect(execute_query.dig("data", "post")).to eq({
        "id" => "1",
        "title" => "option test"
      })

      context[:current_user] = nil

      # now should skip cache
      expect(execute_query.dig("data", "post")).to eq({
        "id" => "1",
        "title" => "new option test"
      })
    end

    context "when :if is a Symbol" do
      let(:cache_fragment) { {if: :no_current_user?} }

      specify do
        expect(execute_query.dig("data", "post")).to eq({
          "id" => "1",
          "title" => "new option test"
        })
      end
    end
  end

  context "when :unless is provided" do
    let(:context) { {current_user: User.new(id: "1", name: "some-user")} }
    let(:cache_fragment) { {unless: -> { context[:current_user].nil? }} }

    specify do
      expect(execute_query.dig("data", "post")).to eq({
        "id" => "1",
        "title" => "option test"
      })

      context[:current_user] = nil

      expect(execute_query.dig("data", "post")).to eq({
        "id" => "1",
        "title" => "new option test"
      })
    end

    context "when :unless is a Symbol" do
      let(:cache_fragment) { {unless: :current_user?} }

      specify do
        expect(execute_query.dig("data", "post")).to eq({
          "id" => "1",
          "title" => "new option test"
        })
      end
    end
  end

  context "when :renew_cache is in the context" do
    let(:context) { {renew_cache: true} }

    it "forces a cache miss and stores the computed value in the cache" do
      expect(execute_query.dig("data", "post")).to eq({
        "id" => "1",
        "title" => "new option test"
      })

      # make object dirty
      post.title = "new option test 2"

      context[:renew_cache] = false
      expect(execute_query.dig("data", "post")).to eq({
        "id" => "1",
        "title" => "new option test"
      })
    end
  end
end
