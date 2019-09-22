require_relative 'spec_helper'
require 'benchmark'

describe Arango::Server do
  context "benchmark http" do
    before :all do
      @server = connect
    end

    it "version works" do
      expect(@server.version).to be_a String
    end

    it "version benchmark" do
      result = nil
      timings = Benchmark.measure do
        1000.times do
          result = @server.version
        end
      end
      STDERR.puts "\n1000 requests: #{timings}"
      expect(result).to be_a String
    end
  end
end
