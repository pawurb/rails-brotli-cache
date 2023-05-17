# Rails Brotli Cache [![Gem Version](https://badge.fury.io/rb/rails-brotli-cache.svg)](https://badge.fury.io/rb/rails-brotli-cache) [![CircleCI](https://circleci.com/gh/pawurb/rails-brotli-cache.svg?style=svg)](https://circleci.com/gh/pawurb/rails-brotli-cache)

This gem enables support for compressing Ruby on Rails cache entries using the Brotli compression algorithm. Brotli is a modern compression algorithm developed by Google that provides superior compression ratios and performance compared to the default Gzip algorithm.

**The gem is currently in an early stage of development. Ideas on how to improve it and PRs are welcome.**

## API

`RailsBrotliCache` module exposes methods that are compatible with the default `Rails.cache`. Values are stored in the underlying `Rails.cache` store but precompressed with Brotli algorithm.

You can use it the default `Rails.cache` API:

```ruby
RailsBrotliCache.read("test-key") => nil
RailsBrotliCache.fetch("test-key") { 123 } => 123
RailsBrotliCache.delete("test-key")
RailsBrotliCache.read("test-key") => nil

```

Gem appends `br-` to the cache key names to prevent conflicts with previously saved cache entries. You can disable this behaviour by adding the following initilizer file:

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
