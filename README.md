# Rails Brotli Cache [![Gem Version](https://badge.fury.io/rb/rails-brotli-cache.svg)](https://badge.fury.io/rb/rails-brotli-cache) [![CircleCI](https://circleci.com/gh/pawurb/rails-brotli-cache.svg?style=svg)](https://circleci.com/gh/pawurb/rails-brotli-cache)

This gem enables support for compressing Ruby on Rails cache entries using the [Brotli compression algorithm](https://github.com/google/brotli). Brotli is a modern compression algorithm developed by Google that provides superior compression ratios and performance compared to the default Gzip algorithm.

**The gem is currently in an early stage of development. Ideas on how to improve it and PRs are welcome.**

## Benchmarks

Brotli offers a better compression and faster performance.

**~25%** better compression of a sample JSON object:

```ruby
json = File.read("sample.json") # sample 565kb JSON text
json.size # => 562033
Rails.cache.write("json", json)
RailsBrotliCache.write("json", json)

## Check the size of cache entry stored in Redis
$redis.get("json").size # => 41697
$redis.get("br-json").size # => 31601
```

**~20%** better compression of a sample ActiveRecord objects array:

```ruby
users = User.limit(100).to_a # 100 ActiveRecord objects
Rails.cache.write("users", users)
RailsBrotliCache.write("users", users)
$redis.get("users").size # => 12331
$redis.get("br-users").size # => 10299
```


**~25%** faster performance for reading/writing a larger JSON file:

```ruby
json = File.read("sample.json") # sample 565kb JSON text

Benchmark.bm do |x|
  x.report("Rails.cache") do
    1000.times do
      Rails.cache.write("test", json)
      Rails.cache.read("test")
    end
  end

  x.report("RailsBrotliCache") do
    1000.times do
      RailsBrotliCache.write("test", json)
      RailsBrotliCache.read("test")
    end
  end
end

# user     system      total        real
# Rails.cache  5.177678   0.216435   5.394113 (  8.296072)
# RailsBrotliCache  3.513312   0.323601   3.836913 (  6.114179)
```

## API

`RailsBrotliCache` module exposes methods that are compatible with the default `Rails.cache`. Values are stored in the underlying `Rails.cache` store but precompressed with Brotli algorithm.

You can use it just like the default `Rails.cache` API:

```ruby
RailsBrotliCache.read("test-key") => nil
RailsBrotliCache.fetch("test-key") { 123 } => 123
RailsBrotliCache.delete("test-key")
RailsBrotliCache.read("test-key") => nil

```

Gem appends `br-` to the cache key names to prevent conflicts with previously saved cache entries. You can disable this behaviour by adding the following initializer file:

`app/config/initializers/rails-brotli-cache.rb`

```ruby
RailsBrotliCache.disable_prefix!
```

## Testing

```bash
cp docker-compose.yml.sample docker-compose.yml
docker compose up -d
rake test_all
```
