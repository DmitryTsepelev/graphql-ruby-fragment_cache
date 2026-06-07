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

  describe "#read" do
    let(:cache_key) { "fragment-cache-key" }
    let(:cache_store) { double("cache_store") }

    let(:fragment) do
      context = double("context")
      allow(context).to receive(:namespace).with(:interpreter).and_return(current_path: ["post"])
      allow(context).to receive(:[]).with(:renew_cache).and_return(nil)

      described_class.new(context).tap do |fragment|
        allow(fragment).to receive(:cache_key).and_return(cache_key)
      end
    end

    before do
      allow(GraphQL::FragmentCache).to receive(:cache_store).and_return(cache_store)
    end

    # Regression test for the race condition fixed in #99: existence is checked
    # with #exist? *before* #read, so a key that is absent at lookup time is
    # reported as a cache miss without being read — instead of being read first
    # and mistaken for a cached nil if another request populates it in between.
    context "when the cache key does not exist" do
      before do
        allow(cache_store).to receive(:exist?).with(cache_key).and_return(false)
        allow(cache_store).to receive(:read).with(cache_key)
      end

      it "returns a cache miss without reading the absent key" do
        expect(fragment.read).to be_nil
        expect(cache_store).not_to have_received(:read)
      end
    end

    context "when a nil value is stored in the cache" do
      before do
        allow(cache_store).to receive(:exist?).with(cache_key).and_return(true)
        allow(cache_store).to receive(:read).with(cache_key).and_return(nil)
      end

      it "returns the sentinel for a cached nil" do
        expect(fragment.read).to be(described_class::NIL_IN_CACHE)
      end
    end

    context "when a value is stored in the cache" do
      before do
        allow(cache_store).to receive(:exist?).with(cache_key).and_return(true)
        allow(cache_store).to receive(:read).with(cache_key).and_return("cached value")
      end

      it "returns the cached value" do
        expect(fragment.read).to eq("cached value")
      end
    end
  end
end
