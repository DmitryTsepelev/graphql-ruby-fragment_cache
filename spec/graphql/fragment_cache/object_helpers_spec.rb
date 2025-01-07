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

    let(:id) { 1 }
    let(:expires_in) { nil }
    let(:variables) { {id: id, expires_in: expires_in} }

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

    context "when query_cache_key option is passed" do
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

    context "when path_cache_key option is passed" do
      let(:resolver) do
        ->(id:, expires_in:) do
          cache_fragment(path_cache_key: "my_key") { Post.find(id) }
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

      context "when query has fragment" do
        let(:author) { User.new(id: 1, name: "John") }
        let!(:post) { Post.create(id: 1, title: "object test", author: author) }

        let(:query_with_fragment) do
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

        let(:resolver) do
          ->(id:) do
            Post.find(id)
          end
        end

        it "returns cached fragment" do
          author_data = execute_query(query_with_fragment).dig("data", "post", "author")
          expect(author_data).to eq({"name" => author.name})
        end

        context "when fragment name is wrong" do
          let(:query_with_fragment) do
            <<~GQL
              fragment PostFragment on PostType {
                id
                author: cachedAuthor {
                  name
                }
              }

              query getPost($id: ID!) {
                post(id: $id) {
                  ...WrongPostFragment
                }
              }
            GQL
          end

          it "returns cached fragment" do
            error_message = execute_query(query_with_fragment).dig("errors").first["message"]
            expect(error_message).to eq("Fragment WrongPostFragment was used, but not defined")
          end
        end
      end

      context "when query has inline fragment" do
        let(:author) { User.new(id: 1, name: "John") }
        let!(:post) { Post.create(id: 1, title: "object test", author: author) }

        let(:query_with_fragment) do
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

        let(:resolver) do
          ->(id:) do
            Post.find(id)
          end
        end

        it "returns cached fragment" do
          author_data = execute_query(query_with_fragment).dig("data", "post", "author")
          expect(author_data).to eq({"name" => author.name})
        end
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

    context "when selection aliases are used" do
      let(:query) do
        <<~GQL
          query getPost($id: ID!) {
            post(id: $id) {
              id
            }
          }
        GQL
      end

      let(:query_with_aliased_selection) do
        <<~GQL
          query getPost($id: ID!) {
            post(id: $id) {
              postId: id
            }
          }
        GQL
      end

      let(:resolver) do
        ->(id:) do
          cache_fragment(Post.find(id))
        end
      end

      it "returns cached fragment for different selection aliases independently" do
        expect(execute_query.dig("data", "post")).to eq({
          "id" => "1"
        })

        expect(execute_query(query_with_aliased_selection).dig("data", "post")).to eq({
          "postId" => "1"
        })
      end
    end

    context "when resolver is used" do
      let(:resolver_class) do
        Class.new(GraphQL::Schema::Resolver) do
          include GraphQL::FragmentCache::ObjectHelpers

          type Types::Post, null: true

          argument :id, GraphQL::Types::ID, required: true
          argument :expires_in, GraphQL::Types::Int, required: false

          def resolve(id:, expires_in: nil)
            cache_fragment { Post.find(id) }
          end
        end
      end

      let(:schema) do
        klass = resolver_class

        build_schema do
          query(
            Class.new(Types::Query) {
              field :post, resolver: klass
            }
          )
        end
      end

      it "returns cached fragment" do
        expect(execute_query.dig("data", "post")).to eq({
          "id" => "1",
          "title" => "object test"
        })
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
          }
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
            }
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
            }
          )
        end

        it "not calls resolver method" do
          allow(::Post).to receive(:all).and_call_original
          execute_query
          expect(::Post).not_to have_received(:all)
        end
      end
    end
  end

  describe "caching fields inside collection elements" do
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

    let(:schema) do
      build_schema do
        query(Types::Query)
      end
    end

    let!(:post1) { Post.create(id: 1, title: "object test 1") }
    let!(:post2) { Post.create(id: 2, title: "object test 2") }

    before do
      # warmup cache
      execute_query
      # make objects dirty
      post1.title = "new object test 1"
      post2.title = "new object test 2"
    end

    it "returns cached results" do
      expect(execute_query.dig("data", "posts")).to eq([
        {
          "id" => "1",
          "cachedTitle" => "object test 1"
        },
        {
          "id" => "2",
          "cachedTitle" => "object test 2"
        }
      ])
    end
  end

  describe "nil caching" do
    let(:schema) do
      build_schema do
        query(
          Class.new(Types::Query) {
            field :post, Types::Post, null: true do
              argument :id, GraphQL::Types::ID, required: true
              argument :expires_in, GraphQL::Types::Int, required: false
            end

            def post(id:, expires_in: nil)
              cache_fragment { Post.find(id) }
            end
          }
        )
      end
    end

    let(:id) { 1 }
    let(:expires_in) { nil }
    let(:variables) { {id: id, expires_in: expires_in} }

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

    before do
      # make sure post won't be created
      Post.store[id] = nil
      # warmup cache
      execute_query
      # create object
      Post.store[id] = Post.create(id: id, title: "object test")
    end

    let(:resolver) do
      ->(id:, expires_in:) do
        cache_fragment { Post.find(id) }
      end
    end

    it "returns cached nil" do
      expect(execute_query.dig("data", "post")).to eq(nil)
    end

    it "not calls resolver method" do
      allow(::Post).to receive(:all).and_call_original
      execute_query
      expect(::Post).not_to have_received(:all)
    end
  end

  context "context caching" do
    let(:resolver) do
      ->(id:) do
        cache_fragment(path_cache_key: "same_post") { Post.find(id) }
      end
    end

    let(:schema) do
      field_resolver = resolver

      build_schema do
        query(
          Class.new(Types::Query) {
            field :post, Types::Post, null: true do
              argument :id, GraphQL::Types::ID, required: true
            end

            define_method(:post, &field_resolver)
          }
        )
      end
    end

    let(:id) { 1 }
    let(:variables) { {id: id} }

    let(:query) do
      <<~GQL
        query getPostManyTimes($id: ID!) {
          post1: post(id: $id) {
            id
            title
          }

          post2: post(id: $id) {
            id
            title
          }

          post3: post(id: $id) {
            id
            title
          }
        }
      GQL
    end

    let!(:post) { Post.create(id: 1, title: "object test") }

    before do
      allow(GraphQL::FragmentCache.cache_store).to receive(:read)
    end

    before do
      # warmup cache
      execute_query
    end

    it "calls #read for each entry" do
      # warmup calls
      expect(GraphQL::FragmentCache.cache_store).to have_received(:read).exactly(3)

      execute_query

      # read key once
      expect(GraphQL::FragmentCache.cache_store).to have_received(:read).exactly(6)
    end

    context "when keep_in_context is true" do
      let(:resolver) do
        ->(id:) do
          cache_fragment(path_cache_key: "same_post", keep_in_context: true) { Post.find(id) }
        end
      end

      it "calls #read once" do
        # warmup calls
        expect(GraphQL::FragmentCache.cache_store).to have_received(:read).exactly(3)

        execute_query

        # read key once
        expect(GraphQL::FragmentCache.cache_store).to have_received(:read).exactly(4)
      end
    end
  end

  describe "caching fields with batch loader" do
    let(:query) do
      <<~GQL
        query GetPosts {
          posts {
            id
            batchedCachedAuthor {
              name
            }
          }
        }
      GQL
    end

    let(:schema) do
      build_schema do
        use GraphQL::Batch
        query(Types::Query)
      end
    end

    let(:user1) { User.new(id: 1, name: "User #1") }
    let(:user2) { User.new(id: 2, name: "User #2") }

    let!(:post1) { Post.create(id: 1, title: "object test 1", author: user1) }
    let!(:post2) { Post.create(id: 2, title: "object test 2", author: user2) }

    before do
      # warmup cache
      execute_query
      # make objects dirty
      user1.name = "User #1 new"
      user2.name = "User #2 new"
    end

    it "returns cached results" do
      expect(execute_query.dig("data", "posts")).to eq([
        {
          "id" => "1",
          "batchedCachedAuthor" => {"name" => "User #1"}
        },
        {
          "id" => "2",
          "batchedCachedAuthor" => {"name" => "User #2"}
        }
      ])
    end
  end

  describe "caching fields with dataloader" do
    let(:query) do
      <<~GQL
        query GetPosts {
          posts {
            id
            dataloaderCachedAuthor {
              name
            }
          }
        }
      GQL
    end

    let(:schema) do
      build_schema do
        use GraphQL::Dataloader
        query(Types::Query)
      end
    end

    let(:user1) { User.new(id: 1, name: "User #1") }
    let(:user2) { User.new(id: 2, name: "User #2") }

    let!(:post1) { Post.create(id: 1, title: "object test 1", author: user1) }
    let!(:post2) { Post.create(id: 2, title: "object test 2", author: user2) }

    let(:memory_store) { GraphQL::FragmentCache::MemoryStore.new }

    before do
      allow(User).to receive(:find_by_post_ids).and_call_original

      # warmup cache
      execute_query

      # make objects dirty
      user1.name = "User #1 new"
      user2.name = "User #2 new"
    end

    it "returns cached results" do
      expect(execute_query.dig("data", "posts")).to eq([
        {
          "id" => "1",
          "dataloaderCachedAuthor" => {"name" => "User #1"}
        },
        {
          "id" => "2",
          "dataloaderCachedAuthor" => {"name" => "User #2"}
        }
      ])

      expect(User).to have_received(:find_by_post_ids).with([post1.id, post2.id]).once
    end
  end

  describe "conditional caching" do
    let(:schema) do
      field_resolver = resolver

      build_schema do
        query(
          Class.new(Types::Query) {
            field :post, Types::Post, null: true do
              argument :id, GraphQL::Types::ID, required: true
            end

            define_method(:post, &field_resolver)
          }
        )
      end
    end

    let(:id) { 1 }
    let(:variables) { {id: id} }

    let(:query) do
      <<~GQL
        query getPost($id: ID!) {
          post(id: $id) {
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

    context "when :if is true" do
      let(:resolver) do
        ->(id:) do
          cache_fragment(if: true) { Post.find(id) }
        end
      end

      it "uses the cache" do
        expect(execute_query.dig("data", "post")).to eq({
          "id" => "1",
          "title" => "object test"
        })
      end
    end

    context "when :if is false" do
      let(:resolver) do
        ->(id:) do
          cache_fragment(if: false) { Post.find(id) }
        end
      end

      it "does not use the cache" do
        expect(execute_query.dig("data", "post")).to eq({
          "id" => "1",
          "title" => "new object test"
        })
      end
    end

    context "when :unless is true" do
      let(:resolver) do
        ->(id:) do
          cache_fragment(unless: true) { Post.find(id) }
        end
      end

      it "does not use the cache" do
        expect(execute_query.dig("data", "post")).to eq({
          "id" => "1",
          "title" => "new object test"
        })
      end
    end

    context "when :unless is false" do
      let(:resolver) do
        ->(id:) do
          cache_fragment(unless: false) { Post.find(id) }
        end
      end

      it "uses the cache" do
        expect(execute_query.dig("data", "post")).to eq({
          "id" => "1",
          "title" => "object test"
        })
      end
    end
  end

  describe "when a default option is configured" do
    let(:query) do
      <<~GQL
        query getPosts {
          posts {
            nodes {
              id
            }
          }
        }
      GQL
    end

    let(:schema) do
      field_resolver = resolver

      build_schema do
        query(
          Class.new(Types::Query) {
            field :posts, Types::Post.connection_type, null: false

            define_method(:posts, &field_resolver)
          }
        )
      end
    end

    before do
      Post.create(id: 1, title: "first post")

      GraphQL::FragmentCache.default_options = {expires_in: 60}
      allow(GraphQL::FragmentCache.cache_store).to receive(:write).and_call_original
    end

    after { GraphQL::FragmentCache.default_options = {} }

    context "when default option is not overriden" do
      let(:resolver) do
        -> do
          posts = Post.all
          cache_fragment(posts)
        end
      end

      it "uses the default option" do
        execute_query

        expect(GraphQL::FragmentCache.cache_store)
          .to have_received(:write)
          .with(anything, anything, hash_including(expires_in: 60))
      end
    end

    context "when default option is overriden" do
      let(:resolver) do
        -> do
          posts = Post.all
          cache_fragment(posts, expires_in: 10)
        end
      end

      it "does not use the default option" do
        execute_query

        expect(GraphQL::FragmentCache.cache_store)
          .to have_received(:write)
          .with(anything, anything, hash_including(expires_in: 10))
      end
    end
  end

  describe "when caching is disabled" do
    let(:schema) do
      field_resolver = resolver

      build_schema do
        query(
          Class.new(Types::Query) {
            field :post, Types::Post, null: true do
              argument :id, GraphQL::Types::ID, required: true
            end

            define_method(:post, &field_resolver)
          }
        )
      end
    end

    let(:id) { 1 }
    let(:variables) { {id: id} }

    let(:query) do
      <<~GQL
        query getPost($id: ID!) {
          post(id: $id) {
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

      GraphQL::FragmentCache.enabled = false
    end

    after { GraphQL::FragmentCache.enabled = true }

    let(:resolver) do
      ->(id:) do
        cache_fragment { Post.find(id) }
      end
    end

    it "does not use the cache" do
      expect(execute_query.dig("data", "post")).to eq({
        "id" => "1",
        "title" => "new object test"
      })
    end
  end
end
