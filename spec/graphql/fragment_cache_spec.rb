# frozen_string_literal: true

require "spec_helper"

describe GraphQL::FragmentCache do
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
