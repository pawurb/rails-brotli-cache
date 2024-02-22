# frozen_string_literal: true

require "spec_helper"

return unless ENV["TEST_RAILS_CACHE_STORE"] == "brotli_cache_store"

describe RailsBrotliCache do
  subject(:cache_store) do
    Rails.cache
  end

  it "sets the correct Rails.cache store" do
    expect(Rails.cache.class).to eq RailsBrotliCache::Store
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
