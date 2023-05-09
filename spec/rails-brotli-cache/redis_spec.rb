# frozen_string_literal: true

require 'spec_helper'
require 'redis'

return unless ENV["TEST_CACHE_STORE"] == "redis_cache_store"
$redis = Redis.new

describe RailsBrotliCache do
  it "sets correct cache store based on ENV variable" do
    expect(Rails.cache.class).to eq ActiveSupport::Cache::RedisCacheStore
  end

  describe "#fetch" do
    it "stores value in the configured redis cache store" do
      RailsBrotliCache.fetch("test-key") { 123 }
      expect($redis.get("br-test-key")).to be_present
    end
  end

  let(:json) do
    File.read('spec/fixtures/sample.json')
  end

  it "applies more efficient brotli compression" do
    Rails.cache.write("gz-test-key", json)
    RailsBrotliCache.write("test-key", json)
    expect($redis.get("gz-test-key").size > $redis.get("br-test-key").size).to eq true
  end

  context "payloads smaller then 1kb" do
    before do
      # expect(Brotli).not_to receive(:deflate)
    end

    it "does not apply compression" do
      RailsBrotliCache.write("test-key", 123)
      expect(RailsBrotliCache.read("test-key")).to eq 123
    end
  end
end
