# frozen_string_literal: true

require 'spec_helper'

return unless ENV['RAILS_CACHE_STORE'] == 'redis_cache_store'

describe RailsBrotliCache do
  subject(:cache_store) do
    RailsBrotliCache::Store.new(
      ActiveSupport::Cache::RedisCacheStore.new(redis: $redis)
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
end
