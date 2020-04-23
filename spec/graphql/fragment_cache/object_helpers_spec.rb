# frozen_string_literal: true

require "spec_helper"

describe "#cache_fragment" do
  describe "scalar caching" do
    let(:schema) do
      field_resolver = resolver

      build_schema do
        query(
          Class.new(Types::Query) {
            field :post, Types::Post, null: true do
              argument :id, GraphQL::Types::ID, required: true
              argument :expires_in, GraphQL::Types::Int, required: false
            end

            define_method(:post, &field_resolver)
          }
        )
      end
    end

    let(:expires_in) { nil }
    let(:variables) { {id: 1, expires_in: expires_in} }

    let(:query) do
      <<~GQL
        query getPost($id: ID!, $expiresIn: Int) {
          post(id: $id, expiresIn: $expiresIn) {
            id
            title
          }
        }
      GQL
    end

    let!(:post) { Post.create(id: 1, title: "object test") }

    before do
      # warmup cache
      execute_query
      # make object dirty
      post.title = "new object test"
    end

    context "when block is passed" do
      let(:resolver) do
        ->(id:, expires_in:) do
          cache_fragment { Post.find(id) }
        end
      end

      it "returns cached fragment" do
        expect(execute_query.dig("data", "post")).to eq({
          "id" => "1",
          "title" => "object test"
        })
      end
    end

    context "when object is passed" do
      let(:resolver) do
        ->(id:, expires_in:) do
          post = Post.find(id)
          cache_fragment(post, expires_in: expires_in)
        end
      end

      it "returns cached fragment" do
        expect(execute_query.dig("data", "post")).to eq({
          "id" => "1",
          "title" => "new object test"
        })

        post.id = 2

        expect(execute_query.dig("data", "post")).to eq({
          "id" => "1",
          "title" => "new object test"
        })
      end

      context "when :expires_in is provided" do
        let(:expires_in) { 60 }

        it "returns new fragment after expiration" do
          Timecop.travel(Time.now + 61)

          expect(execute_query.dig("data", "post")).to eq({
            "id" => "1",
            "title" => "new object test"
          })
        end
      end
    end

    context "when key part option is passed" do
      let(:resolver) do
        ->(id:, expires_in:) do
          cache_fragment(query_cache_key: "my_key") { Post.find(id) }
        end
      end

      it "returns the same cache fragment for a different query when query_cache_key is constant" do
        variables[:id] = 2

        expect(execute_query.dig("data", "post")).to eq({
          "id" => "1",
          "title" => "object test"
        })
      end
    end

    context "when block and object are passed" do
      let(:resolver) do
        ->(id:, expires_in:) do
          post_id = id
          cache_fragment(id, expires_in: expires_in) { Post.find(post_id) }
        end
      end

      it "uses object as key and return block result" do
        expect(execute_query.dig("data", "post")).to eq({
          "id" => "1",
          "title" => "object test"
        })

        post.title = "new object title"

        # it still return the cached data
        expect(execute_query.dig("data", "post")).to eq({
          "id" => "1",
          "title" => "object test"
        })
      end
    end

    context "when alias is used" do
      let(:query) do
        <<~GQL
          query getPost($id: ID!) {
            postById: post(id: $id) {
              id
            }
          }
        GQL
      end

      let(:another_query) do
        <<~GQL
          query getPost($id: ID!) {
            postById: post(id: $id) {
              id
              title
            }
          }
        GQL
      end

      let(:resolver) do
        ->(id:) do
          cache_fragment { Post.find(id) }
        end
      end

      let(:variables) { {id: 1} }

      it "returns cached fragment" do
        expect(execute_query.dig("data", "postById")).to eq({
          "id" => "1"
        })

        post.title = "new object title"

        expect(execute_query(another_query).dig("data", "postById")).to eq({
          "id" => "1",
          "title" => "new object title"
        })
      end

      context "with multiple aliases" do
        let(:query) do
          <<~GQL
            query getPost($id: ID!, $anotherId: ID!) {
              postById: post(id: $id) {
                id
                title
                meta
              }
              postById2: post(id: $anotherId) {
                id
                title
                meta
              }
            }
          GQL
        end

        let(:resolver) do
          ->(id:) do
            cache_fragment(Post.find(id))
          end
        end

        let(:variables) { {id: 1, another_id: 2} }

        let!(:post2) { Post.create(id: 2, title: "another test") }

        it "returns cached fragment for different aliases independently" do
          expect(execute_query.dig("data", "postById")).to eq({
            "id" => "1",
            "title" => "new object test",
            "meta" => nil
          })

          expect(execute_query.dig("data", "postById2")).to eq({
            "id" => "2",
            "title" => "another test",
            "meta" => nil
          })

          post.title = "new object title"
          post2.meta = "invisible"
          variables.replace(id: 2, another_id: 1)

          expect(execute_query.dig("data", "postById2")).to eq({
            "id" => "1",
            "title" => "new object title",
            "meta" => nil
          })

          expect(execute_query.dig("data", "postById")).to eq({
            "id" => "2",
            "title" => "another test",
            "meta" => nil
          })
        end
      end
    end
  end

  describe "connection caching" do
    let(:query) do
      <<~GQL
        query getPosts($before: String, $after: String) {
          posts(before: $before, after: $after) {
            nodes {
              id
              title
            }
            pageInfo {
              startCursor
              endCursor
              hasNextPage
              hasPreviousPage
            }
          }
        }
      GQL
    end

    let(:after) { nil }
    let(:before) { nil }
    let(:variables) { {after: after, before: before} }

    before do
      Post.create(id: 1, title: "first post")
      Post.create(id: 2, title: "second post")
    end

    context "when new_connections are configured" do
      let(:schema) do
        build_schema do
          query(
            Class.new(Types::Query) {
              field :posts, Types::Post.connection_type, null: false, cache_fragment: true

              def posts
                Post.all
              end
            }
          )
        end
      end

      before do
        execute_query
      end

      it "returns cached fragment" do
        expect(execute_query.dig("data", "posts")).to eq(
          "nodes" => [
            {"id" => "1", "title" => "first post"},
            {"id" => "2", "title" => "second post"}
          ],
          "pageInfo" => {
            "startCursor" => schema.cursor_encoder.encode("1"),
            "endCursor" => schema.cursor_encoder.encode("2"),
            "hasNextPage" => false,
            "hasPreviousPage" => false
          },
        )
      end

      it "not calls resolver method" do
        allow(::Post).to receive(:all).and_call_original
        execute_query
        expect(::Post).not_to have_received(:all)
      end

      context "when after is passed" do
        let(:after) { schema.cursor_encoder.encode("1") }

        it "returns cached fragment" do
          expect(execute_query.dig("data", "posts")).to eq(
            "nodes" => [
              {"id" => "2", "title" => "second post"}
            ],
            "pageInfo" => {
              "startCursor" => schema.cursor_encoder.encode("2"),
              "endCursor" => schema.cursor_encoder.encode("2"),
              "hasNextPage" => false,
              "hasPreviousPage" => true
            },
          )
        end

        it "not calls resolver method" do
          allow(::Post).to receive(:all).and_call_original
          execute_query
          expect(::Post).not_to have_received(:all)
        end
      end

      context "when before is passed" do
        let(:before) { schema.cursor_encoder.encode("2") }

        it "returns cached fragment" do
          expect(execute_query.dig("data", "posts")).to eq(
            "nodes" => [
              {"id" => "1", "title" => "first post"}
            ],
            "pageInfo" => {
              "startCursor" => schema.cursor_encoder.encode("1"),
              "endCursor" => schema.cursor_encoder.encode("1"),
              "hasNextPage" => true,
              "hasPreviousPage" => false
            },
          )
        end

        it "not calls resolver method" do
          allow(::Post).to receive(:all).and_call_original
          execute_query
          expect(::Post).not_to have_received(:all)
        end
      end
    end

    context "when new_connections are not configured" do
      let(:schema) do
        Class.new(GraphQL::Schema) do
          use GraphQL::Execution::Interpreter
          use GraphQL::Analysis::AST
          use GraphQL::FragmentCache

          query(
            Class.new(Types::Query) {
              field :posts, Types::Post.connection_type, null: false, cache_fragment: true

              def posts
                Post.all
              end
            }
          )
        end
      end

      it "raises error" do
        expect {
          execute_query
        }.to raise_error(
          StandardError, "GraphQL::Pagination::Connections should be enabled for connection caching"
        )
      end
    end
  end
end
