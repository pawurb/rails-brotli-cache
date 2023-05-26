# frozen_string_literal: true

require 'spec_helper'

describe RailsBrotliCache do
  subject(:cache_store) do
    RailsBrotliCache::Store.new(ActiveSupport::Cache::MemoryStore.new)
  end

  describe "#fetch" do
    it "stores value in the configured Rails.cache with a prefix" do
      cache_store.fetch("test-key") { 123 }
      expect(cache_store.read("test-key")).to eq 123
    end

    it "returns nil for missing entries if block is not provided" do
      expect(cache_store.fetch("missing-key")).to eq nil
    end

    it "executes block only once" do
      counter = 0
      cache_store.fetch("forced-key") { counter += 1 }
      cache_store.fetch("forced-key") { counter += 1 }
      expect(cache_store.read("forced-key")).to eq 1
    end

    context "{ force: true }" do
      it "raises an error if block is not provided" do
        expect {
          cache_store.fetch("missing-key", force: true)
        }.to raise_error(ArgumentError)
      end

      it "always refreshes cached entry if block is provided" do
        counter = 0
        cache_store.fetch("forced-key", force: true) { counter += 1 }
        cache_store.fetch("forced-key", force: true) { counter += 1 }
        expect(cache_store.read("forced-key")).to eq 2
      end
    end
  end

  describe "#increment and #decrement" do
    it "works" do
      cache_store.write("integer-key", 0)
      cache_store.increment("integer-key")
      expect(cache_store.read("integer-key")).to eq 1
      cache_store.increment("integer-key", 3)
      expect(cache_store.read("integer-key")).to eq 4
      cache_store.decrement("integer-key", 4)
      expect(cache_store.read("integer-key")).to eq 0
      cache_store.decrement("integer-key")
      expect(cache_store.read("integer-key")).to eq -1
    end
  end

  describe "exist?" do
    it "returns true if cache entry exists" do
      cache_store.write("test-key", 1234)
      expect(cache_store.exist?("test-key")).to eq true
    end

    it "returns false if cache entry does not exist" do
      expect(cache_store.exist?("test-key")).to eq false
    end
  end

  describe "#core_store" do
    it "exposes the underlying data store" do
      expect(cache_store.core_store.class).to eq ActiveSupport::Cache::MemoryStore
    end
  end

  describe "#read and #write" do
    it "reads values stored in Rails cache with a prefix" do
      expect(cache_store.read("test-key")).to eq nil
      expect(cache_store.write("test-key", 1234))
      expect(cache_store.read("test-key")).to eq 1234
    end

    context "payloads smaller then 1kb" do
      before do
        expect(Brotli).not_to receive(:deflate)
      end

      it "does not apply compression" do
        cache_store.write("test-key", 123)
        expect(cache_store.read("test-key")).to eq 123
      end
    end
  end

  describe "#delete" do
    it "removes the previously stored cache entry" do
      expect(cache_store.write("test-key", 1234))
      expect(cache_store.read("test-key")).to eq 1234
      cache_store.delete("test-key")
      expect(cache_store.read("test-key")).to eq nil
    end
  end
end
