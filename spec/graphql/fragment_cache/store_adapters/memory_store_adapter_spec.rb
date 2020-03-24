# frozen_string_literal: true

require "spec_helper"

require "redis"
require "connection_pool"

RSpec.describe GraphQL::FragmentCache::StoreAdapters::MemoryStoreAdapter do
  subject { described_class.new({}) }

  describe "#set" do
    context "when :expires_in is passed" do
      it "raises error" do
        expect { subject.set("key", "value", expires_in: 1) }.to raise_error(
          ArgumentError,
          ":memory adapter does not accept :expires_in parameter, consider switching to :redis"
        )
      end
    end
  end
end
