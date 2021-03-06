require_relative './../../spec_helper'

describe Arango::Server do
  context "#verbose" do
    it "try verbose" do
      @server.verbose = true
      result = @myDatabase.collection(name: "Test").create
      expect(result.class).to be Arango::Collection
    end

    it "print verbose" do
      @server.verbose = true
      expect(@server.verbose).to be true
      @server.verbose = false
    end
  end
end
