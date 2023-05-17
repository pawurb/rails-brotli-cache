# frozen_string_literal: true

require 'spec_helper'

describe RailsBrotliCache do
  context "without prepending Rails.cache" do
    describe "#fetch" do
      it "stores value in the configured Rails.cache with a prefix" do
        RailsBrotliCache.fetch("test-key") { 123 }
        expect(RailsBrotliCache.read("test-key")).to eq 123
        expect(Rails.cache.read("br-test-key")).to be_present
      end

      it "returns nil for missing entries if block is not provided" do
        expect(RailsBrotliCache.fetch("missing-key")).to eq nil
      end

      context "{ force: true }" do
        it "raises an error if block is not provided" do
          expect {
            RailsBrotliCache.fetch("missing-key", force: true)
          }.to raise_error(ArgumentError)
        end

        it "always refreshes cached entry if block is provided" do

        end
      end
    end

    describe "#read and #write" do
      it "reads values stored in Rails cache with a prefix" do
        expect(RailsBrotliCache.read("test-key")).to eq nil
        expect(RailsBrotliCache.write("test-key", 1234))
        expect(RailsBrotliCache.read("test-key")).to eq 1234
      end
    end
  end
end
