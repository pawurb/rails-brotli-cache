# frozen_string_literal: true

require 'rails-brotli-cache/base'
require 'rails-brotli-cache/version'

module RailsBrotliCache
  extend RailsBrotliCache::Base

  def self.enable!
    Rails.cache.class.prepend(RailsBrotliCache::Base)
  end
end

