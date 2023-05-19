# frozen_string_literal: true

require 'spec_helper'

return unless ENV['RAILS_CACHE_STORE'] == 'redis_cache_store'

describe RailsBrotliCache do
  let(:options) do
    {}
  end

  subject(:cache_store) do
    RailsBrotliCache::Store.new(
      ActiveSupport::Cache::RedisCacheStore.new(redis: $redis),
      options
    )
  end

  describe "#fetch" do
    it "stores value in the configured redis cache store" do
      cache_store.fetch("test-key") { 123 }
      expect($redis.get("br-test-key")).to be_present
    end
  end

  let(:json) do
    File.read('spec/fixtures/sample.json')
  end

  it "applies more efficient brotli compression" do
    Rails.cache.write("gz-test-key", json)
    cache_store.write("test-key", json)
    expect($redis.get("gz-test-key").size > $redis.get("br-test-key").size).to eq true
  end

  describe "disable_prefix" do
    context "default prefix" do
      it "appends 'br-' prefix" do
        cache_store.fetch("test-key") { 123 }
        expect($redis.get("test-key")).to eq nil
        expect($redis.get("br-test-key")).to be_present
      end
    end

    context "no prefix" do
      let(:options) do
        { prefix: nil }
      end

      it "saves brotli cache entries without `br-` prefix" do
        cache_store.fetch("test-key") { 123 }
        expect($redis.get("br-test-key")).to eq nil
        expect($redis.get("test-key")).to be_present
      end
    end
  end
end
