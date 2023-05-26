# frozen_string_literal: true

require 'spec_helper'

describe RailsBrotliCache do

  CACHE_STORE_TYPES = [
    [ActiveSupport::Cache::MemoryStore.new, ActiveSupport::Cache::MemoryStore.new],
    [ActiveSupport::Cache::RedisCacheStore.new, ActiveSupport::Cache::RedisCacheStore.new],
    [ActiveSupport::Cache::MemCacheStore.new, ActiveSupport::Cache::MemCacheStore.new],
    [ActiveSupport::Cache::FileStore.new('./tmp'), ActiveSupport::Cache::FileStore.new('./tmp')],
    [ActiveSupport::Cache::NullStore.new, ActiveSupport::Cache::NullStore.new]
  ]

  CACHE_STORE_TYPES.each do |cache_store_types|
    describe "Brotli cache has the same API as #{cache_store_types[0].class}" do
      subject(:brotli_store) do
        RailsBrotliCache::Store.new(cache_store_types[0])
      end

      let(:standard_cache) do
        cache_store_types[1]
      end

      it "compares the same cache stores" do
        expect(standard_cache.class).to eq(brotli_store.core_store.class)
      end

      it "for #clear" do
        expect(brotli_store.clear.class).to eq(standard_cache.clear.class)
      end

      it "for #read and #write" do
        int_val = 123
        expect(brotli_store.write("int_val_key", int_val).class).to eq(standard_cache.write("int_val_key", int_val).class)
        expect(brotli_store.read("int_val_key")).to eq(standard_cache.read("int_val_key"))

        str_val = "str"
        expect(brotli_store.write("str_val_key", int_val).class).to eq(standard_cache.write("str_val_key", int_val).class)
        expect(brotli_store.read("str_val_key")).to eq(standard_cache.read("str_val_key"))

        complex_val = OpenStruct.new(a: 1, b: 2)
        expect(brotli_store.write("complex_val_key", int_val).class).to eq(standard_cache.write("complex_val_key", int_val).class)
        expect(brotli_store.read("complex_val_key")).to eq(standard_cache.read("complex_val_key"))
      end

      it "for #increment and #decrement" do
        expect(brotli_store.write("inc_val_key", 1).class).to eq(standard_cache.write("inc_val_key", 1).class)
        expect(brotli_store.increment("inc_val_key").class).to eq(standard_cache.increment("inc_val_key").class)
        expect(brotli_store.read("inc_val_key")).to eq(standard_cache.read("inc_val_key"))
        expect(brotli_store.increment("inc_val_key", 2).class).to eq(standard_cache.increment("inc_val_key", 2).class)
        expect(brotli_store.read("inc_val_key")).to eq(standard_cache.read("inc_val_key"))
        expect(brotli_store.decrement("inc_val_key", 2).class).to eq(standard_cache.decrement("inc_val_key", 2).class)
        expect(brotli_store.read("inc_val_key")).to eq(standard_cache.read("inc_val_key"))
      end

      it "for #fetch" do
        val = "123"
        expect(brotli_store.fetch("val_key") { val }).to eq(standard_cache.fetch("val_key") { val })
        expect(brotli_store.fetch("val_key", force: true) { val }).to eq(standard_cache.fetch("val_key", force: true) { val })
        expect(brotli_store.fetch("val_key")).to eq(standard_cache.fetch("val_key"))
      end
    end
  end
end
