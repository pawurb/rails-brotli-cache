# frozen_string_literal: true

require 'spec_helper'

describe RailsBrotliCache do
  context "without prepending Rails.cache" do
    describe "#fetch" do
      it "stores value in the configured Rails.cache" do
        puts Rails.cache.class
      end
    end

    describe "#read" do

    end

    describe "#write" do

    end

  end
end
