# frozen_string_literal: true

require "spec_helper"

RSpec.describe GraphQL::FragmentCache::StoreAdapters::RedisClientBuilder do
  describe "#initialize" do
    let(:options) { {} }

    subject { described_class.new(options).build }

    context "when redis_host, redis_port and redis_db_name are passed" do
      let(:options) do
        { redis_host: "127.0.0.2", redis_port: "2214", redis_db_name: "7" }
      end

      it "builds redis URL" do
        expect(subject.connection[:id]).to eq("redis://127.0.0.2:2214/7")
      end
    end

    context "when REDIS_URL is configured" do
      let(:redis_url) { "redis://127.0.0.1:6379" }

      before do
        allow(ENV).to receive(:[]).with("REDIS_URL").and_return(redis_url)
      end

      it "uses default db" do
        expect(subject.connection[:id]).to eq("redis://127.0.0.1:6379/0")
      end

      context "when redis_db_name is configured" do
        let(:options) { { redis_db_name: "42" } }

        it "uses configured db" do
          expect(subject.connection[:id]).to eq("redis://127.0.0.1:6379/42")
        end
      end
    end

    context "when redis_url is passed" do
      let(:options) { { redis_url: "redis://127.0.0.4:2177/22" } }

      it "uses passed redis_url" do
        expect(subject.connection[:id]).to eq("redis://127.0.0.4:2177/22")
      end

      context "when passed along with other parameters" do
        let(:options) do
          {
            redis_url: "redis://127.0.0.1:6379",
            redis_host: "127.0.0.1",
            redis_port: "6379",
            redis_db_name: "0"
          }
        end

        it "raises error" do
          expect { subject }.to raise_error(
            ArgumentError,
            "redis_url cannot be passed along with redis_host, redis_port or redis_db_name options"
          )
        end
      end
    end
  end
end
