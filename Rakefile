require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc "Test all cache_stores"
task :test_all do
  system("TEST_RAILS_CACHE_STORE=redis_cache_store bundle exec rspec spec && TEST_RAILS_CACHE_STORE=brotli_cache_store bundle exec rspec spec && TEST_RAILS_CACHE_STORE=mem_cache_store bundle exec rspec spec && bundle exec rspec spec")
end
