require_relative 'spec_helper'
require 'benchmark'

describe Arango::Server do
  context "benchmark http" do
    it "force_version works" do
      result = @server.force_version
      expect(result).to include(server: 'arango')
    end

    it "force_version works" do
      result = nil
      timings = Benchmark.measure do
        1000.times do
          result = @server.force_version
        end
      end
      STDERR.puts "1000 rounds: #{timings}"
      expect(result).to include(server: 'arango')
    end
  end
end