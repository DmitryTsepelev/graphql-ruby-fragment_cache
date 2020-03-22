# frozen_string_literal: true

require "spec_helper"

require "redis"
require "connection_pool"

RSpec.describe GraphQL::FragmentCache::StoreAdapters::RedisStoreAdapter do
  subject { described_class.new(options) }

  let(:expiration) { nil }
  let(:options) do
    {
      redis_client: redis_client,
      expiration: expiration
    }
  end

  context "when Hash instance is passed" do
    let(:redis_client) { { redis_url: "redis://127.0.0.3:8791/3" } }

    it "wraps with proc" do
      expect(subject.instance_variable_get("@redis_proc")).to be_kind_of(Proc)
    end
  end

  context "when Proc instance is passed" do
    let(:redis_client) { proc {} }

    it "wraps with proc" do
      expect(subject.instance_variable_get("@redis_proc")).to be_kind_of(Proc)
    end
  end

  context "when Redis instance is passed" do
    let(:redis_client) { Redis.new(url: "redis://127.0.0.3:8791/3") }

    it "wraps with proc" do
      expect(subject.instance_variable_get("@redis_proc")).to be_kind_of(Proc)
    end
  end

  context "when ConnectionPool instance is passed" do
    let(:redis_client) { ConnectionPool.new { Redis.new(url: "redis://127.0.0.3:8791/3") } }

    it "wraps with proc" do
      expect(subject.instance_variable_get("@redis_proc")).to be_kind_of(Proc)
    end
  end

  context "when expiration is not passed" do
    let(:redis_client) { proc {} }

    it "falls back to the default expiration" do
      expect(subject.instance_variable_get("@expiration")).to eq(86400)
    end
  end

  context "when expiration is passed" do
    let(:redis_client) { proc {} }
    let(:expiration) { 1_000_000 }

    it "uses the passed expiration" do
      expect(subject.instance_variable_get("@expiration")).to eq(expiration)
    end
  end

  context "when not supported object is passed" do
    let(:redis_client) { 42 }

    it "raises error" do
      expect { subject }.to raise_error(
        ArgumentError,
        ":redis_client accepts Redis, ConnectionPool, Hash or Proc only"
      )
    end
  end
end
