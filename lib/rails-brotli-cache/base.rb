# frozen_string_literal: true

module RailsBrotliCache::Base
  def fetch(*params)
    puts "my fetch"
    super
  end

  def write(*params)
    puts "my save"
    super
  end

  def read(*params)
    puts "my read"
    super
  end
end
