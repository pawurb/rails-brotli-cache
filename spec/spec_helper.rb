require 'rubygems'
require 'bundler/setup'
require 'rails'

require_relative '../lib/rails-brotli-cache'
require_relative '../spec/dummy/config/environment'
ENV['RAILS_ROOT'] ||= "#{File.dirname(__FILE__)}../../../spec/dummy"

RSpec.configure do |config|
  config.before(:each) do
    Rails.cache.clear
  end
end

