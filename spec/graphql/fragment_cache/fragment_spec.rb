# frozen_string_literal: true

require "spec_helper"

describe GraphQL::FragmentCache::Fragment do
  describe "#read_multi" do
    context "when all fragments don't have renew_cache in their context" do
      it "calls read_multi and returns the cached values for all of them" do
        fragment_doubles = fragment_doubles_factory(count: 3)
        cache_store_double = double("cache_store", read_multi: fragment_doubles.map { |f| [f.cache_key, f.read] }.to_h)

        allow(GraphQL::FragmentCache).to receive(:cache_store).and_return(cache_store_double)

        expect(described_class.read_multi(fragment_doubles).values).to eq fragment_doubles.map(&:read)
        expect(cache_store_double).to have_received(:read_multi).with(*fragment_doubles.map(&:cache_key))
      end
    end

    context "when all fragments have renew_cache: true in their context" do
      it "it does not call read_multi and returns a nil value for all of them" do
        fragment_doubles = fragment_doubles_factory(count: 3, ctx: {renew_cache: true})
        cache_store_double = double("cache_store", read_multi: fragment_doubles.map { |f| [f.cache_key, f.read] }.to_h)

        allow(GraphQL::FragmentCache).to receive(:cache_store).and_return(cache_store_double)

        expect(described_class.read_multi(fragment_doubles).values).to eq fragment_doubles.map { nil }
        expect(cache_store_double).not_to have_received(:read_multi)
      end
    end

    context "when some fragments have renew_cache: true in their context and other don't" do
      it "it does not call read_multi for the ones with renew_cache: true and returns a nil value for them" do
        renew_fragment_doubles = fragment_doubles_factory(count: 3, ctx: {renew_cache: true})
        # use sample to randomly select from contexts that should not renew the cache
        invalid_context = {renew_cache: [false, "false", 1, 3.14159].sample}
        cache_fragment_doubles = fragment_doubles_factory(count: 3, ctx: invalid_context)
        fragment_doubles = cache_fragment_doubles + renew_fragment_doubles
        cache_store_double = double("cache_store", read_multi: cache_fragment_doubles.map { |f| [f.cache_key, f.read] }.to_h)

        allow(GraphQL::FragmentCache).to receive(:cache_store).and_return(cache_store_double)

        expect(described_class.read_multi(fragment_doubles).values).to eq cache_fragment_doubles.map(&:read) + renew_fragment_doubles.map { nil }
        expect(cache_store_double).to have_received(:read_multi).with(*cache_fragment_doubles.map(&:cache_key))
      end
    end

    # creates an array of fragment doubles with random cache_keys and read values
    def fragment_doubles_factory(count:, ctx: {})
      (1..count).map do |i|
        r = srand
        instance_double(GraphQL::FragmentCache::Fragment, context: ctx, read: r, cache_key: r.to_s)
      end
    end
  end
end
