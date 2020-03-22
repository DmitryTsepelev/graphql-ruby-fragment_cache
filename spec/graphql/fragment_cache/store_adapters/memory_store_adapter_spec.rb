# frozen_string_literal: true

require "spec_helper"

require "redis"
require "connection_pool"

RSpec.describe GraphQL::FragmentCache::StoreAdapters::MemoryStoreAdapter do
  subject { described_class.new({}) }

  describe "#set" do
    context "when :ex is passed" do
      it "raises error" do
        expect { subject.set("key", "value", ex: 1) }.to raise_error(
          ArgumentError,
          ":memory adapter does not accept :ex parameter, consider switching to :redis"
        )
      end
    end
  end
end
