# frozen_string_literal: true

require 'rails-brotli-cache/version'
require 'brotli'

module RailsBrotliCache
  COMPRESS_THRESHOLD = ENV.fetch("BR_CACHE_COMPRESS_THRESHOLD", 0).to_f * 1024.0
  COMPRESS_QUALITY = ENV.fetch("BR_CACHE_COMPRESS_QUALITY", 5).to_i
  MARK_BR_COMPRESSED = "\x02".b

  def self.fetch(name, options = {}, &block)
    value = read(name, options)
    return value if value.present?

    if block_given?
      value = block.call
      write(name, value, options)

      value
    elsif options && options[:force]
      raise ArgumentError, "Missing block: Calling `Cache#fetch` with `force: true` requires a block."
    else
      read(name, options)
    end
  end

  def self.write(name, value, options = {})
    serialized = Marshal.dump(value)

    payload = if serialized.bytesize >= COMPRESS_THRESHOLD
      MARK_BR_COMPRESSED + ::Brotli.deflate(serialized, quality: COMPRESS_QUALITY)
    else
      serialized
    end

    Rails.cache.write(
      cache_key(name),
      payload,
      options.merge(compress: false)
    )
  end

  def self.read(name, options = {})
    payload = Rails.cache.read(
      cache_key(name),
      options
    )

    return nil unless payload.present?

    serialized = if payload.start_with?(MARK_BR_COMPRESSED)
      ::Brotli.inflate(payload.byteslice(1..-1))
    else
      payload
    end

    Marshal.load(serialized)
  end

  def self.cache_key(name)
    "br-#{name}"
  end
end
