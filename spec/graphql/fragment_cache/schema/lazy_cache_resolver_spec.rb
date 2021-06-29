# frozen_string_literal: true

require "spec_helper"

describe GraphQL::FragmentCache::Schema::LazyCacheResolver do
  describe "#initialize" do
    context "lazy cache resolver state management" do
      let(:state_key) { :lazy_cache_resolver_statez }

      it "adds lazy state property to the query context" do
        context = {}

        expect(context).not_to have_key(state_key)

        GraphQL::FragmentCache::Schema::LazyCacheResolver.new(nil, context, {})

        expect(context).to have_key(state_key)
      end

      it "has :pending_fragments Set in state" do
        context = {}

        GraphQL::FragmentCache::Schema::LazyCacheResolver.new({}, context, {})

        expect(context[state_key]).to have_key(:pending_fragments)
        expect(context[state_key][:pending_fragments]).to be_instance_of(Set)
      end

      it "has :resolved_fragments Hash in state" do
        context = {}

        GraphQL::FragmentCache::Schema::LazyCacheResolver.new({}, context, {})

        expect(context[state_key]).to have_key(:resolved_fragments)
        expect(context[state_key][:resolved_fragments]).to be_instance_of(Hash)
      end

      it "pushes fragments into :pending_fragments" do
        context = {}
        fragments = []

        3.times { fragments.push(Object.new) }

        fragments.each do |f|
          GraphQL::FragmentCache::Schema::LazyCacheResolver.new(f, context, {})
        end

        fragments.each do |f|
          expect(context[state_key][:pending_fragments]).to include(f)
        end
      end
    end
  end

  it "has :resolve method" do
    lazy_cache_resolver = GraphQL::FragmentCache::Schema::LazyCacheResolver.new({}, {}, {})

    expect(lazy_cache_resolver).to respond_to(:resolve)
  end
end
