# frozen_string_literal: true

require 'active_support/cache'
require 'brotli'

module RailsBrotliCache
  class Store < ::ActiveSupport::Cache::Store
    COMPRESS_THRESHOLD = ENV.fetch("BR_CACHE_COMPRESS_THRESHOLD", 1).to_f * 1024.0
    COMPRESS_QUALITY = ENV.fetch("BR_CACHE_COMPRESS_QUALITY", 5).to_i
    MARK_BR_COMPRESSED = "\x02".b

    def initialize(core_store, options = {})
      @core_store = core_store
      @prefix = "br-"
    end

    def fetch(name, options = nil, &block)
      value = read(name, options)

      if value.present? && !options&.fetch(:force, false) == true
        return value
      end

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

    def write(name, value, options = nil)
      serialized = Marshal.dump(value)

      payload = if serialized.bytesize >= COMPRESS_THRESHOLD
        MARK_BR_COMPRESSED + ::Brotli.deflate(serialized, quality: COMPRESS_QUALITY)
      else
        serialized
      end

      @core_store.write(
        cache_key(name),
        payload,
        (options || {}).merge(compress: false)
      )
    end

    def read(name, options = nil)
      payload = @core_store.read(
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

    def delete(name, options = nil)
      @core_store.delete(cache_key(name), options)
    end

    def clear(options = nil)
      @core_store.clear
    end

    def disable_prefix!
      @@prefix = nil
    end

    private

    def cache_key(name)
      "#{@prefix}#{name}"
    end
  end
end
