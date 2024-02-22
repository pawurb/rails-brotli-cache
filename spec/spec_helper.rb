require "rubygems"
require "bundler/setup"
require "active_support"
require "active_support/core_ext/hash"
require "redis"

require_relative "../lib/rails-brotli-cache"

$redis = Redis.new
$test_rails_cache_store = if ENV["TEST_RAILS_CACHE_STORE"] == "redis_cache_store"
    ActiveSupport::Cache::RedisCacheStore.new(redis: $redis)
  elsif ENV["TEST_RAILS_CACHE_STORE"] == "brotli_cache_store"
    RailsBrotliCache::Store.new(ActiveSupport::Cache::MemoryStore.new)
  elsif ENV["TEST_RAILS_CACHE_STORE"] == "memcache_cache_store"
    ActiveSupport::Cache::ActiveSupport::Cache::MemCacheStore.new
  else
    ActiveSupport::Cache::MemoryStore.new
  end

require_relative "../spec/dummy/config/environment"
ENV["RAILS_ROOT"] ||= "#{File.dirname(__FILE__)}../../../spec/dummy"

RSpec.configure do |config|
  config.before(:each) do
    Rails.cache.clear
  end
end
