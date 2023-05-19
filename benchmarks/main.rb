require 'rails'
require 'net/http'
require 'rails-brotli-cache'

memory_cache = ActiveSupport::Cache::MemoryStore.new(compress: true) # memory store does not use compression by default
brotli_memory_cache = RailsBrotliCache::Store.new(memory_cache)
redis_cache = ActiveSupport::Cache::RedisCacheStore.new
brotli_redis_cache = RailsBrotliCache::Store.new(redis_cache)
memcached_cache = ActiveSupport::Cache::MemCacheStore.new
brotli_memcached_cache = RailsBrotliCache::Store.new(memcached_cache)

json_uri = URI("https://raw.githubusercontent.com/pawurb/rails-brotli-cache/main/spec/fixtures/sample.json")
json = Net::HTTP.get(json_uri)

iterations = 100

Benchmark.bm do |x|
  x.report("memory_cache") do
    iterations.times do
      memory_cache.write("test", json)
      memory_cache.read("test")
    end
  end

  x.report("brotli_memory_cache") do
    iterations.times do
      brotli_memory_cache.write("test", json)
      brotli_memory_cache.read("test")
    end
  end

  x.report("redis_cache") do
    iterations.times do
      redis_cache.write("test", json)
      redis_cache.read("test")
    end
  end

  x.report("brotli_redis_cache") do
    iterations.times do
      brotli_redis_cache.write("test", json)
      brotli_redis_cache.read("test")
    end
  end

  x.report("memcached_cache") do
    iterations.times do
      memcached_cache.write("test", json)
      memcached_cache.read("test")
    end
  end

  x.report("brotli_memcached_cache") do
    iterations.times do
      brotli_memcached_cache.write("test", json)
      brotli_memcached_cache.read("test")
    end
  end
end
