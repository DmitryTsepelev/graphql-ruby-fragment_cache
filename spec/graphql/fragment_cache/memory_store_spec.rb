# frozen_string_literal: true

require "spec_helper"

describe GraphQL::FragmentCache::MemoryStore do
  subject { described_class.new }

  it "caches writes" do
    subject.write(:test, "42")
    expect(subject.read(:test)).to eq "42"
  end

  it "is symbol/string insensitive" do
    subject.write(:test, "42")
    expect(subject.read("test")).to eq "42"
  end

  it "supports expires_in option" do
    subject.write(:test, "42", expires_in: 5)
    expect(subject.read(:test)).to eq "42"

    Timecop.travel Time.now + 6

    expect(subject.read(:test)).to be_nil
  end

  context "with expires_in: option" do
    subject { described_class.new(expires_in: 5) }

    it "uses default expiration time" do
      subject.write(:test, "42")
      expect(subject.read(:test)).to eq "42"

      Timecop.travel Time.now + 6

      expect(subject.read(:test)).to be_nil
    end

    it "uses explicit expiration if provided" do
      subject.write(:test, "42", expires_in: 15)
      expect(subject.read(:test)).to eq "42"

      Timecop.travel Time.now + 6

      expect(subject.read(:test)).to eq "42"

      Timecop.travel Time.now + 10

      expect(subject.read(:test)).to be_nil
    end
  end

  it "raises if unsupported options are passed" do
    expect { described_class.new(namespace: "test") }
      .to raise_error(ArgumentError, /unsupported options: namespace/i)
  end
end
