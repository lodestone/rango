require_relative 'spec_helper'
require 'benchmark'

describe Arango::Server do
  context "benchmark http" do
    before :all do
      @server = connect
    end

    it "force_version works" do
      result = @server.version
      expect(result[:server]).to eq('arango')
    end

    it "force_version benchmark" do
      result = nil
      timings = Benchmark.measure do
        1000.times do
          result = @server.version
        end
      end
      STDERR.puts "1000 requests: #{timings}"
      expect(result[:server]).to eq('arango')
    end
  end
end