# Rails Brotli Cache [![Gem Version](https://badge.fury.io/rb/rails-brotli-cache.svg)](https://badge.fury.io/rb/rails-brotli-cache) [![CircleCI](https://circleci.com/gh/pawurb/rails-brotli-cache.svg?style=svg)](https://circleci.com/gh/pawurb/rails-brotli-cache)

This gem enables support for compressing Ruby on Rails cache entries using the [Brotli compression algorithm](https://github.com/google/brotli). `RailsBrotliCache` offers better compression and faster performance compared to the default `Rails.cache` regardless of the underlying data store.

**The gem is currently in an early stage of development. Ideas on how to improve it and PRs are welcome.**

## Benchmarks

Brotli cache works as a proxy layer wrapping the underlying cache data store.

```ruby
default_cache = ActiveSupport::Cache::RedisCacheStore.new(redis: $redis)
brotli_cache = RailsBrotliCache::Store.new(default_cache)
```

**~25%** better compression of a sample JSON object:

```ruby
json = File.read("sample.json") # sample 435kb JSON text
json.size # => 435662
default_cache.write("json", json)
brotli_cache.write("json", json)

## Check the size of cache entry stored in Redis
$redis.get("json").size # => 31698
$redis.get("br-json").size # => 24058
```

**~20%** better compression of a sample ActiveRecord objects array:

```ruby
users = User.limit(100).to_a # 100 ActiveRecord objects
default_cache.write("users", users)
brotli_cache.write("users", users)
$redis.get("users").size # => 12331
$redis.get("br-users").size # => 10299
```

**~25%** faster performance for reading/writing a larger JSON file:

```ruby
json = File.read("sample.json") # sample 435kb JSON text

Benchmark.bm do |x|
  x.report("default_cache") do
    1000.times do
      default_cache.write("test", json)
      default_cache.read("test")
    end
  end

  x.report("brotli_cache") do
    1000.times do
      brotli_cache.write("test", json)
      brotli_cache.read("test")
    end
  end
end

# user     system      total        real
# default_cache  5.177678   0.216435   5.394113 (  8.296072)
# brotli_cache   3.513312   0.323601   3.836913 (  6.114179)
```

## Configuration

Gem works as a drop-in replacement for a standard Rails cache store. Here's how you can configure it with different store types:

```ruby
config.cache_store = RailsBrotliCache::Store.new(
  ActiveSupport::Cache::RedisCacheStore.new(redis: $redis)
)
```

```ruby
config.cache_store = RailsBrotliCache::Store.new(
  ActiveSupport::Cache::MemoryStore.new
)
```

```ruby
config.cache_store = RailsBrotliCache::Store.new(
  ActiveSupport::Cache::MemCacheStore.new("localhost:11211")
)
```

Gem appends `br-` to the cache key names to prevent conflicts with previously saved cache entries. You can disable this behaviour by adding the following initializer file:

`app/config/initializers/rails-brotli-cache.rb`

```ruby
Rails.cache.disable_prefix!
```

## Testing

```bash
cp docker-compose.yml.sample docker-compose.yml
docker compose up -d
rake test_all
```
