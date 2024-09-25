require "active_support"
require "active_support/core_ext/hash"
require "net/http"
require "brotli"
require "rails-brotli-cache"
require "benchmark"
require "zstd-ruby"
require "lz4-ruby"

class ZSTDCompressor
  def self.deflate(payload)
    ::Zstd.compress(payload, level: 10)
  end

  def self.inflate(payload)
    ::Zstd.decompress(payload)
  end
end

class LZ4Compressor
  def self.deflate(payload)
    ::LZ4::compress(payload)
  end

  def self.inflate(payload)
    ::LZ4::uncompress(payload)
  end
end

class LZ4HCCompressor
  def self.deflate(payload)
    ::LZ4::compressHC(payload)
  end

  def self.inflate(payload)
    ::LZ4::uncompress(payload)
  end
end

memory_cache = ActiveSupport::Cache::MemoryStore.new(compress: true) # memory store does not use compression by default
brotli_memory_cache = RailsBrotliCache::Store.new(memory_cache)
zstd_memory_cache = RailsBrotliCache::Store.new(memory_cache, compressor_class: ZSTDCompressor, prefix: "zs-")
lz4_memory_cache = RailsBrotliCache::Store.new(memory_cache, compressor_class: LZ4Compressor, prefix: "lz4-")
lz4hc_memory_cache = RailsBrotliCache::Store.new(memory_cache, compressor_class: LZ4HCCompressor, prefix: "lz4hc-")

redis_cache = ActiveSupport::Cache::RedisCacheStore.new
brotli_redis_cache = RailsBrotliCache::Store.new(redis_cache)
zstd_redis_cache = RailsBrotliCache::Store.new(redis_cache, compressor_class: ZSTDCompressor, prefix: "zs-")
lz4_redis_cache = RailsBrotliCache::Store.new(redis_cache, compressor_class: LZ4Compressor, prefix: "lz4-")
lz4hc_redis_cache = RailsBrotliCache::Store.new(redis_cache, compressor_class: LZ4HCCompressor, prefix: "lz4hc-")

memcached_cache = ActiveSupport::Cache::MemCacheStore.new
brotli_memcached_cache = RailsBrotliCache::Store.new(memcached_cache)
zstd_memcached_cache = RailsBrotliCache::Store.new(memcached_cache, compressor_class: ZSTDCompressor, prefix: "zs-")
lz4_memcached_cache = RailsBrotliCache::Store.new(memcached_cache, compressor_class: LZ4Compressor, prefix: "lz4-")
lz4hc_memcached_cache = RailsBrotliCache::Store.new(memcached_cache, compressor_class: LZ4HCCompressor, prefix: "lz4hc-")

file_cache = ActiveSupport::Cache::FileStore.new("/tmp")
brotli_file_cache = RailsBrotliCache::Store.new(file_cache)
zstd_file_cache = RailsBrotliCache::Store.new(file_cache, compressor_class: ZSTDCompressor, prefix: "zs-")
lz4_file_cache = RailsBrotliCache::Store.new(file_cache, compressor_class: LZ4Compressor, prefix: "lz4-")
lz4hc_file_cache = RailsBrotliCache::Store.new(file_cache, compressor_class: LZ4HCCompressor, prefix: "lz4hc-")

json_uri = URI("https://raw.githubusercontent.com/pawurb/rails-brotli-cache/main/spec/fixtures/sample.json")
json = Net::HTTP.get(json_uri)

puts "Uncompressed JSON size: #{json.size}"
redis_cache.write("gz-json", json)
gzip_json_size = redis_cache.redis.with do |conn|
  conn.get("gz-json").size
end
puts "Gzip JSON size: #{gzip_json_size}"
brotli_redis_cache.write("json", json)
br_json_size = redis_cache.redis.with do |conn|
  conn.get("br-json").size
end
puts "Brotli JSON size: #{br_json_size}"
puts "~#{((gzip_json_size - br_json_size).to_f / gzip_json_size.to_f * 100).round}% difference"
puts ""

zstd_redis_cache.write("json", json)
zs_json_size = redis_cache.redis.with do |conn|
  conn.get("zs-json").size
end
puts "ZSTD JSON size: #{zs_json_size}"
puts "~#{((gzip_json_size - zs_json_size).to_f / gzip_json_size.to_f * 100).round}% difference"
puts ""

lz4_redis_cache.write("json", json)
lz4_json_size = redis_cache.redis.with do |conn|
  conn.get("lz4-json").size
end
puts "LZ4 JSON size: #{lz4_json_size}"
puts "~#{((gzip_json_size - lz4_json_size).to_f / gzip_json_size.to_f * 100).round}% difference"
puts ""

lz4hc_redis_cache.write("json", json)
lz4hc_json_size = redis_cache.redis.with do |conn|
  conn.get("lz4hc-json").size
end
puts "LZ4HC JSON size: #{lz4hc_json_size}"
puts "~#{((gzip_json_size - lz4hc_json_size).to_f / gzip_json_size.to_f * 100).round}% difference"
puts ""

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

  x.report("zstd_memory_cache") do
    iterations.times do
      zstd_memory_cache.write("test", json)
      zstd_memory_cache.read("test")
    end
  end

  x.report("lz4_memory_cache") do
    iterations.times do
      lz4_memory_cache.write("test", json)
      lz4_memory_cache.read("test")
    end
  end

  x.report("lz4hc_memory_cache") do
    iterations.times do
      lz4hc_memory_cache.write("test", json)
      lz4hc_memory_cache.read("test")
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

  x.report("zstd_redis_cache") do
    iterations.times do
      zstd_redis_cache.write("test", json)
      zstd_redis_cache.read("test")
    end
  end

  x.report("lz4_redis_cache") do
    iterations.times do
      lz4_redis_cache.write("test", json)
      lz4_redis_cache.read("test")
    end
  end

  x.report("lz4hc_redis_cache") do
    iterations.times do
      lz4hc_redis_cache.write("test", json)
      lz4hc_redis_cache.read("test")
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

  x.report("zstd_memcached_cache") do
    iterations.times do
      zstd_memcached_cache.write("test", json)
      zstd_memcached_cache.read("test")
    end
  end

  x.report("lz4_memcached_cache") do
    iterations.times do
      lz4_memcached_cache.write("test", json)
      lz4_memcached_cache.read("test")
    end
  end

  x.report("lz4hc_memcached_cache") do
    iterations.times do
      lz4hc_memcached_cache.write("test", json)
      lz4hc_memcached_cache.read("test")
    end
  end

  x.report("file_cache") do
    iterations.times do
      file_cache.write("test", json)
      file_cache.read("test")
    end
  end

  x.report("brotli_file_cache") do
    iterations.times do
      brotli_file_cache.write("test", json)
      brotli_file_cache.read("test")
    end
  end

  x.report("zstd_file_cache") do
    iterations.times do
      zstd_file_cache.write("test", json)
      zstd_file_cache.read("test")
    end
  end

  x.report("lz4_file_cache") do
    iterations.times do
      lz4_file_cache.write("test", json)
      lz4_file_cache.read("test")
    end
  end

  x.report("lz4hc_file_cache") do
    iterations.times do
      lz4hc_file_cache.write("test", json)
      lz4hc_file_cache.read("test")
    end
  end
end
