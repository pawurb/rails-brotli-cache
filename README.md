# Rails Brotli Cache [![Gem Version](https://img.shields.io/gem/v/rails-brotli-cache)](https://badge.fury.io/rb/rails-brotli-cache) [![CircleCI](https://circleci.com/gh/pawurb/rails-brotli-cache.svg?style=svg)](https://circleci.com/gh/pawurb/rails-brotli-cache)

This gem enables support for compressing Ruby on Rails cache entries using the [Brotli compression algorithm](https://github.com/google/brotli). `RailsBrotliCache::Store` offers better compression and performance compared to the default `Rails.cache` Gzip, regardless of the underlying data store. The gem also allows specifying any custom compression algorithm instead of Brotli.

## Benchmarks

Brotli cache works as a proxy layer wrapping the standard cache data store. It applies Brotli compression instead of the default Gzip before storing cache entries.

```ruby
redis_cache = ActiveSupport::Cache::RedisCacheStore.new(
  url: "redis://localhost:6379"
)
brotli_redis_cache = RailsBrotliCache::Store.new(redis_cache)
```

**~25%** better compression of a sample JSON object:

```ruby
json = File.read("sample.json") # sample 435kb JSON text
json.size # => 435662
redis_cache.write("json", json)
brotli_redis_cache.write("json", json)

## Check the size of cache entries stored in Redis
redis = Redis.new(url: "redis://localhost:6379")
redis.get("json").size # => 31698 ~31kb
redis.get("br-json").size # => 24058 ~24kb
```

**~20%** better compression of a sample ActiveRecord objects array:

```ruby
users = User.limit(100).to_a # 100 ActiveRecord objects
redis_cache.write("users", users)
brotli_redis_cache.write("users", users)

redis.get("users").size # => 12331 ~12kb
redis.get("br-users").size # => 10299 ~10kb
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

# redis_cache  1.782225   0.049936   1.832161 (  2.523317)
# brotli_redis_cache  1.218365   0.051084   1.269449 (  1.850894)
# memcached_cache  1.766268   0.045351   1.811619 (  2.504233)
# brotli_memcached_cache  1.194646   0.051750   1.246396 (  1.752982)
# file_cache  1.727967   0.071138   1.799105 (  1.799229)
# brotli_file_cache  1.128514   0.044308   1.172822 (  1.172983)
```

Regardless of the underlying data store, Brotli cache offers 20%-40% performance improvement.

You can run the benchmarks by executing:

```ruby
cp docker-compose.yml.sample docker-compose.yml
docker compose up -d
cd benchmarks
bundle install
bundle exec ruby main.rb
```

## Configuration

Gem works as a drop-in replacement for a standard Rails cache store. You can configure it with different store types:

```ruby
config.cache_store = RailsBrotliCache::Store.new(
  ActiveSupport::Cache::RedisCacheStore.new(url: "redis://localhost:6379")
)
```

```ruby
config.cache_store = RailsBrotliCache::Store.new(
  ActiveSupport::Cache::MemCacheStore.new("localhost:11211")
)
```

```ruby
config.cache_store = RailsBrotliCache::Store.new(
  ActiveSupport::Cache::FileStore.new('/tmp')
)
```

You should avoid using it with `ActiveSupport::Cache::MemoryStore`. This type of cache store does not serialize or compress objects but keeps them directly in the RAM. In this case, adding this gem would reduce RAM usage but add huge performance overhead.

Gem appends `br-` to the cache key names to prevent conflicts with previously saved entries. You can disable this behavior by passing `{ prefix: nil }` during initialization:

```ruby
config.cache_store = RailsBrotliCache::Store.new(
  ActiveSupport::Cache::RedisCacheStore.new,
  { prefix: nil }
)
```

Addition of the prefix means that you can safely add the Brotli the cache config and avoid compression algorithm conflicts between old and new entries. After configuring the Brotli cache you should run `Rails.cache.clear` to remove the outdated (gzipped) entries.

### Use a custom compressor class

By default gem uses a Brotli compression, but you can customize the algorithm. You can pass a `compressor_class` object as a store configuration argument or directly to `read/write/fetch` methods:

```ruby
config.cache_store = RailsBrotliCache::Store.new(
  ActiveSupport::Cache::RedisCacheStore.new,
  { compressor_class: Snappy }
)
```

```ruby
Rails.cache.write('test-key', json, compressor_class: Snappy)
```

This config expects a class which defines two class methods `inflate` and `deflate`. It allows you to instead use for example a [Google Snappy algorithm](https://github.com/miyucy/snappy) offering even better performance for the cost of worse compresion ratios. Optionally, you can define a custom class wrapping any compression library.

## Testing

```bash
cp docker-compose.yml.sample docker-compose.yml
docker compose up -d
rake test_all
```
