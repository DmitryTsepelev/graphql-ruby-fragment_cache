# frozen_string_literal: true

require "spec_helper"

RSpec.describe GraphQL::FragmentCache::StoreAdapters do
  describe ".build" do
    let(:options) { nil }
    subject { described_class.build(adapter, options) }

    context "when StoreAdapters::BaseStoreAdapter instance is passed" do
      let(:adapter) do
        GraphQL::FragmentCache::StoreAdapters::MemoryStoreAdapter.new(options)
      end

      it { is_expected.to be(adapter) }
    end

    context "when name is passed" do
      let(:adapter) { :memory }

      it { is_expected.to be_a(GraphQL::FragmentCache::StoreAdapters::MemoryStoreAdapter) }

      context "when adapter is not found" do
        let(:adapter) { :unknown }

        it "raises error" do
          expect { subject }.to raise_error(
            NameError,
            "Fragment cache store adapter for :#{adapter} haven't been found"
          )
        end
      end
    end
  end
end
