require 'spec_helper'

describe Arango::Index do
  before :all do
    @server = connect
    begin
      @server.delete_database(name: "IndexDatabase")
    rescue
    end
    @database = @server.create_database(name: "IndexDatabase")
  end

  before :each do
    begin
      @database.delete_collection(name: "IndexCollection")
    rescue
    end
    @collection = @database.create_collection(name: "IndexCollection")
  end

  after :each do
    begin
      @database.delete_collection(name: "IndexCollection")
    rescue
    end
  end

  after :all do
    @server.delete_database(name: "IndexDatabase")
  end

  context "Index" do
    it "can create a new index" do
      index = Arango::Index.new(collection: @collection, fields: ["checksum"], id: "TestIndex")
      result = index.create
      expect(result.response_code).to eq 201
    end
    it "can list existing indices" do
      result = Arango::Index.list(collection: @collection)
      expect(result.indexes.class).to be Array
    end
  end

end
