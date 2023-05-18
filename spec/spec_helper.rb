require 'rubygems'
require 'bundler/setup'
require 'rails'
require 'redis'

require_relative '../lib/rails-brotli-cache'

$redis = Redis.new
$rails_cache_store = if ENV['RAILS_CACHE_STORE'] == 'redis_cache_store'
  ActiveSupport::Cache::RedisCacheStore.new(redis: $redis)
elsif ENV['RAILS_CACHE_STORE'] == 'brotli_cache_store'
  RailsBrotliCache::Store.new(ActiveSupport::Cache::MemoryStore.new)
else
  ActiveSupport::Cache::MemoryStore.new
end

require_relative '../spec/dummy/config/environment'
ENV['RAILS_ROOT'] ||= "#{File.dirname(__FILE__)}../../../spec/dummy"

RSpec.configure do |config|
  config.before(:each) do
    Rails.cache.clear
  end
end

