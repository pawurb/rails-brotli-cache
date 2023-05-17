# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rails-brotli-cache/version'

Gem::Specification.new do |gem|
  gem.name          = "rails-brotli-cache"
  gem.version       = RailsBrotliCache::VERSION
  gem.authors       = ["pawurb"]
  gem.email         = ["contact@pawelurbanek.com"]
  gem.summary       = %q{ Rails cache using Brotli compression algorithm }
  gem.description   = %q{ rails-brotli-cache allows to reduce storage needed for Rails cache by using Brotli compression which can produce outputs smaller by ~20% }
  gem.homepage      = "https://github.com/pawurb/rails-brotli-cache"
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = gem.files.grep(%r{^(spec)/})
  gem.require_paths = ["lib"]
  gem.license       = "MIT"
  gem.add_dependency "rails"
  gem.add_dependency "brotli"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "redis"
  gem.add_development_dependency "dalli"
  gem.add_development_dependency "byebug"
end
