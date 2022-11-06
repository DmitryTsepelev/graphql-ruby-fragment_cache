# frozen_string_literal: true

require "spec_helper"

describe GraphQL::FragmentCache do
  describe ".use" do
    if GraphQL::FragmentCache.graphql_ruby_before_2_0?
      it "raises if interpreter is not used" do
        expect {
          Class.new(GraphQL::Schema) {
            use GraphQL::Execution::Execute
            use GraphQL::FragmentCache
          }
        }.to raise_error(
          StandardError, "GraphQL::Execution::Interpreter should be enabled for fragment caching"
        )
      end

      it "raise if interpreter is used without AST" do
        expect {
          Class.new(GraphQL::Schema) do
            use GraphQL::Analysis
            use GraphQL::FragmentCache
          end
        }.to raise_error(
          StandardError, "GraphQL::Analysis::AST should be enabled for fragment caching"
        )
      end

      it "doesn't raise if interpreter is used with AST" do
        expect {
          Class.new(GraphQL::Schema) do
            use GraphQL::FragmentCache
          end
        }.not_to raise_error
      end
    end
  end

  describe ".cache_store=" do
    around do |ex|
      old_store = described_class.cache_store
      ex.run
      described_class.cache_store = old_store
    end

    it "raises if store doesn't implement #read method" do
      expect { described_class.cache_store = Object.new }
        .to raise_error(ArgumentError, /must implement #read/i)
    end

    it "raises if store doesn't implement #write method" do
      obj = Object.new
      obj.singleton_class.define_method(:read) {}

      expect { described_class.cache_store = obj }
        .to raise_error(ArgumentError, /must implement #write/i)
    end

    it "accepts object implementing both #read and #write" do
      obj = Object.new
      obj.singleton_class.define_method(:read) {}
      obj.singleton_class.define_method(:write) {}

      expect { described_class.cache_store = obj }.not_to raise_error
    end
  end

  describe ".configure" do
    it "accepts options with a block notation" do
      obj = GraphQL::FragmentCache::MemoryStore.new

      described_class.configure do |config|
        config.cache_store = obj
      end

      expect(described_class.cache_store).to eq obj
    end
  end
end
