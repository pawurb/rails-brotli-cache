# Rails Brotli Cache [![Gem Version](https://badge.fury.io/rb/rails-brotli-cache.svg)](https://badge.fury.io/rb/rails-brotli-cache) [![CircleCI](https://circleci.com/gh/pawurb/rails-brotli-cache.svg?style=svg)](https://circleci.com/gh/pawurb/rails-brotli-cache)

This gem enables support for compressing Ruby on Rails cache entries using the [Brotli compression algorithm](https://github.com/google/brotli). `RailsBrotliCache` offers better compression and faster performance compared to the default `Rails.cache` regardless of the underlying data store.

**The gem is currently in an early stage of development. Ideas on how to improve it and PRs are welcome.**

## Benchmarks

Brotli cache works as a proxy layer wrapping the underlying cache data store.

```ruby
redis_cache = ActiveSupport::Cache::RedisCacheStore.new
brotli_redis_cache = RailsBrotliCache::Store.new(redis_cache)
```

**~25%** better compression of a sample JSON object:

```ruby
json = File.read("sample.json") # sample 435kb JSON text
json.size # => 435662
redis_cache.write("json", json)
brotli_redis_cache.write("json", json)

## Check the size of cache entry stored in Redis
$redis.get("json").size # => 31698
$redis.get("br-json").size # => 24058
```

**~20%** better compression of a sample ActiveRecord objects array:

```ruby
users = User.limit(100).to_a # 100 ActiveRecord objects
redis_cache.write("users", users)
brotli_redis_cache.write("users", users)
$redis.get("users").size # => 12331
$redis.get("br-users").size # => 10299
```

**~25%** faster performance for reading/writing a larger JSON file:

```ruby
json = File.read("sample.json") # sample ~1mb JSON text

Benchmark.bm do |x|
  x.report("redis_cache") do
    100.times do
      redis_cache.write("test", json)
      redis_cache.read("test")
    end
  end

  x.report("brotli_redis_cache") do
    100.times do
      brotli_redis_cache.write("test", json)
      brotli_redis_cache.read("test")
    end
  end

  # ...
end

# memory_cache  2.081221   0.051615   2.132836 (  2.132877)
# brotli_memory_cache  1.134411   0.032996   1.167407 (  1.167418)
# redis_cache  1.782225   0.049936   1.832161 (  2.523317)
# brotli_redis_cache  1.218365   0.051084   1.269449 (  1.850894)
# memcached_cache  1.766268   0.045351   1.811619 (  2.504233)
# brotli_memcached_cache  1.194646   0.051750   1.246396 (  1.752982)
```

Regardless of the underlying data store, Brotli cache offers between 20%-40% performance improvment.

You can run the benchmarks yourself by executing:

```ruby
cp docker-compose.yml.sample docker-compose.yml
docker compose up -d
cd benchmarks
bundle install
ruby main.rb
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
