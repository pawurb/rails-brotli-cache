# frozen_string_literal: true

require 'spec_helper'

describe RailsBrotliCache do
  subject(:cache_store) do
    RailsBrotliCache::Store.new(
      ActiveSupport::Cache::MemoryStore.new,
      options
    )
  end

  let(:big_enough_to_compress_value) do
    SecureRandom.hex(2048)
  end

  let(:options) do
    {}
  end

  class DummyCompressor
    def self.deflate(payload)
      Zlib::Deflate.deflate(payload)
    end

    def self.inflate(payload)
      Zlib::Inflate.inflate(payload)
    end
  end

  class Post
    include ActiveModel::Model

    attr_accessor :id

    def to_param
      "post/#{id}"
    end
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
      cache_store.fetch("test-key") { counter += 1 }
      cache_store.fetch("test-key") { counter += 1 }
      expect(cache_store.read("test-key")).to eq 1
    end

    it "stores and reads fragment caches with complex objects as cache keys" do
      cached_fragment = "<div>Cached fragment</div>"

      collection = [Post.new(id: 1), Post.new(id: 2)]

      cache_store.fetch([:views, "controller/action", collection]) { cached_fragment }
      expect(cache_store.read([:views, "controller/action", collection])).to eq(cached_fragment)
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

    it "stores value in the configured Rails.cache when options passed" do
      cache_store.fetch("test-key", expires_in: 5.seconds) { big_enough_to_compress_value }
      expect(cache_store.read("test-key")).to eq big_enough_to_compress_value
    end
  end

  describe "#write_multi and #read_multi" do
    it "works" do
      values = {
        "key_1" => big_enough_to_compress_value,
        "key_2" => 123
      }

      cache_store.write_multi(values, expires_in: 5.seconds)
      expect(cache_store.read_multi("key_1", "key_2")).to eq values
    end
  end

  describe "fetch_multi" do
    subject do
      cache_store.fetch_multi(*keys) do |key|
        big_enough_to_compress_value + key
      end
    end

    let(:keys) { %w[key_1 key_2] }
    let(:response) do
      {
        'key_1' => big_enough_to_compress_value + 'key_1',
        'key_2' => big_enough_to_compress_value + 'key_2'
      }
    end

    it "works" do
      expect(subject).to eq response
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
    let(:one_kb_value) do
      SecureRandom.hex(512)
    end

    it "reads values stored in Rails cache with a prefix" do
      expect(cache_store.read("test-key")).to eq nil
      expect(cache_store.write("test-key", big_enough_to_compress_value))
      expect(cache_store.read("test-key")).to eq big_enough_to_compress_value
    end

    it "writes and reads fragment caches with complex objects as cache keys" do
      cached_fragment = "<div>Cached fragment</div>"

      collection = [Post.new(id: 1), Post.new(id: 2)]

      cache_store.write([:views, "controller/action", [collection, nil]], cached_fragment)
      expect(cache_store.read([:views, "controller/action", [collection, nil]])).to eq(cached_fragment)
    end

    describe ":compressor_class option" do
      context "as an init config" do
        let(:options) do
          { compressor_class: DummyCompressor }
        end

        it "calls the custom compressor_class" do
          expect(DummyCompressor).to receive(:deflate).and_call_original
          cache_store.write("test-key", one_kb_value)
          expect(DummyCompressor).to receive(:inflate).and_call_original
          cache_store.read("test-key")
        end
      end

      context "as an method call" do
        it "calls the custom compressor_class" do
          expect(DummyCompressor).to receive(:deflate).and_call_original
          cache_store.write("test-key", one_kb_value, compressor_class: DummyCompressor)
          expect(DummyCompressor).to receive(:inflate).and_call_original
          cache_store.read("test-key", compressor_class: DummyCompressor)
        end
      end
    end

    describe ":compress_threshold option" do
      it "applies compression for larger objects" do
        expect(Brotli).to receive(:deflate).and_call_original
        cache_store.write("test-key", one_kb_value)
      end

      it "does not apply compression for smaller objects" do
        expect(Brotli).not_to receive(:deflate)
        cache_store.write("test-key", 123)
      end

      context "custom :compress_threshold value" do
        let(:options) do
          { compress_threshold: 2.kilobyte }
        end

        it "does not apply compression for objects smaller then custom threshold" do
          expect(Brotli).not_to receive(:deflate)
          cache_store.write("test-key", one_kb_value)
        end
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

  describe "#clear" do
    it "clears the cache" do
      expect(cache_store.write("test-key", 1234))
      expect(cache_store.read("test-key")).to eq 1234
      cache_store.clear
      expect(cache_store.read("test-key")).to eq nil
    end
  end
end
