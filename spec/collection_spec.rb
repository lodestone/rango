require 'spec_helper'

describe Arango::Collection do
  before :all do
    @server = connect
    begin
      @server.drop_database("DocumentCollectionDatabase")
    rescue
    end
    @database = @server.create_database("DocumentCollectionDatabase")
  end

  before :each do
    begin
      @database.drop_collection('MyCollection')
    rescue
    end
  end

  after :each do
    begin
      @database.drop_collection('MyCollection')
    rescue
    end
  end

  after :all do
    @server.drop_database("DocumentCollectionDatabase")
  end

  context "Database" do
    it "new_collection" do
      collection = @database.new_collection("MyCollection")
      expect(collection.name).to eq "MyCollection"
      expect(collection.type).to eq :document
    end

    it "new_collection with type Edge" do
      collection = @database.new_collection "MyCollection", type: :edge
      expect(collection.name).to eq "MyCollection"
      expect(collection.type).to eq :edge
    end

    it "new_edge_collection" do
      collection = @database.new_edge_collection "MyCollection"
      expect(collection.name).to eq "MyCollection"
      expect(collection.type).to eq :edge
    end

    it "create_collection" do
      collection = @database.create_collection "MyCollection"
      expect(collection.name).to eq "MyCollection"
      expect(collection.type).to eq :document
    end

    it "create_edge_collection" do
      collection = @database.create_edge_collection "MyCollection"
      expect(collection.name).to eq "MyCollection"
      expect(collection.type).to eq :edge
    end

    it "get_collection document type" do
      @database.create_collection "MyCollection"
      collection = @database.get_collection("MyCollection")
      expect(collection.name).to eq "MyCollection"
      expect(collection.type).to eq :document
    end

    it "get_collection edge type" do
      @database.create_edge_collection "MyCollection"
      collection = @database.get_collection("MyCollection")
      expect(collection.name).to eq "MyCollection"
      expect(collection.type).to eq :edge
    end

    it "get_collection edge type" do
      @database.create_edge_collection "MyCollection"
      collection = @database.get_collection("MyCollection")
      expect(collection.name).to eq "MyCollection"
      expect(collection.type).to eq :edge
    end

    it "list_collections" do
      @database.create_collection "MyCollection"
      list = @database.list_collections
      expect(list).to include("MyCollection")
    end

    it "drop_collection" do
      @database.create_collection "MyCollection"
      list = @database.list_collections
      expect(list).to include("MyCollection")
      @database.drop_collection("MyCollection")
      list = @database.list_collections
      expect(list).not_to include("MyCollection")
    end

    it "exist_collection?" do
      @database.create_collection "MyCollection"
      result = @database.collection_exist?("MyCollection")
      expect(result).to be true
      result = @database.collection_exist?("StampCollection")
      expect(result).to be false
    end

    it "all_collections" do
      @database.create_collection "MyCollection"
      collections = @database.all_collections
      list = collections.map(&:name)
      expect(list).to include("MyCollection")
      expect(collections.first.class).to be Arango::Collection
    end
  end

  # context "#create" do
  #   it "create a new Collection" do
  #     @collection.destroy
  #     collection = @collection.create
  #     expect(collection.name).to eq "MyCollection"
  #   end
  #
  #   it "create a duplicate Collection" do
  #     error = nil
  #     begin
  #       @collection.create
  #     rescue Arango::ErrorDB => e
  #       error = e.error_num
  #     end
  #     expect(error.class).to eq Integer
  #   end
  #
  #   it "create a new Edge Collection" do
  #     @myEdgeCollection.destroy
  #     collection = @myEdgeCollection.create
  #     expect(collection.type).to eq :edge
  #   end
  #
  #   it "create a new Document in the Collection" do
  #     myDocument = @collection.create_documents document:
  #       {Hello: "World", num: 1}
  #     expect(myDocument[0].body[:Hello]).to eq "World"
  #   end
  #
  #   it "create new Documents in the Collection" do
  #     myDocument = @collection.create_documents document: [{Ciao: "Mondo", num: 1}, {Hallo: "Welt", num: 2}]
  #     expect(myDocument[0].body[:Ciao]).to eq "Mondo"
  #   end
  #
  #   it "create a new Edge in the Collection" do
  #     myDoc = @collection.create_documents document: [{A: "B", num: 1}, {C: "D", num: 3}]
  #     myEdge = @myEdgeCollection.create_edges from: myDoc[0].id, to: myDoc[1].id
  #     expect(myEdge[0].body[:_from]).to eq myDoc[0].id
  #   end
  # end
  #
  # context "#info" do
  #   it "retrieve the Collection" do
  #     info = @collection.retrieve
  #     expect(info.name).to eq "MyCollection"
  #   end
  #
  #   it "properties of the Collection" do
  #     info = @collection.properties
  #     expect(info[:name]).to eq "MyCollection"
  #   end
  #
  #   it "documents in the Collection" do
  #     info = @collection.count
  #     expect(info).to eq 5
  #   end
  #
  #   it "statistics" do
  #     info = @collection.statistics
  #     expect(info[:cacheInUse]).to eq false
  #   end
  #
  #   it "checksum" do
  #     info = @collection.checksum
  #     expect(info.class).to eq String
  #   end
  #
  #   it "list Documents" do
  #     info = @collection.all_documents
  #     expect(info.length).to eq 5
  #   end
  #
  #   it "search Documents by match" do
  #     info = @collection.documents_match match: {num: 1}
  #     expect(info.length).to eq 3
  #   end
  #
  #   it "search Document by match" do
  #     info = @collection.document_match match: {num: 1}
  #     expect(info.collection.name).to eq "MyCollection"
  #   end
  #
  #   it "search Document by key match" do
  #     docs = @collection.create_documents document: [{_key: "ThisIsATest1", test: "fantastic"}, {_key: "ThisIsATest2"}]
  #     result = @collection.documents_by_keys keys: ["ThisIsATest1", docs[1]]
  #     expect(result[0].body[:test]).to eq "fantastic"
  #   end
  #
  #   it "remove Document by key match" do
  #     docs = @collection.create_documents document: [{_key: "ThisIsATest3", test: "fantastic"}, {_key: "ThisIsATest4"}]
  #     result = @collection.remove_by_keys keys: ["ThisIsATest3", docs[1]]
  #     expect(result[:removed]).to eq 2
  #   end
  #
  #   it "remove Document by match" do
  #     @collection.create_documents document: [{_key: "ThisIsATest5", test: "fantastic"}, {_key: "ThisIsATest6"}]
  #     result = @collection.remove_match match: {test: "fantastic"}
  #     expect(result).to eq 2
  #   end
  #
  #   it "replace Document by match" do
  #     @collection.create_documents document: {test: "fantastic", val: 4}
  #     result = @collection.replace_match match: {test: "fantastic"}, newValue: {val: 5}
  #     expect(result).to eq 1
  #   end
  #
  #   it "update Document by match" do
  #     @collection.create_documents document: {test: "fantastic2", val: 5}
  #     result = @collection.update_match match: {val: 5}, newValue: {val: 6}
  #     expect(result).to eq 2
  #   end
  #
  #   it "search random Document" do
  #     info = @collection.random
  #     expect(info.collection.name).to eq "MyCollection"
  #   end
  # end
  #
  # context "#modify" do
  #   it "load" do
  #     collection = @collection.load
  #     expect(collection.name).to eq "MyCollection"
  #   end
  #
  #   it "unload" do
  #     collection = @collection.unload
  #     expect(collection.name).to eq "MyCollection"
  #   end
  #
  #   it "change" do
  #     collection = @collection.change wait_for_sync: true
  #     expect(collection.body[:waitForSync]).to be true
  #   end
  #
  #   it "rename" do
  #     collection = @collection.rename newName: "MyCollection2"
  #     expect(collection.name).to eq "MyCollection2"
  #   end
  # end
  #
  # context "#truncate" do
  #   it "truncate a Collection" do
  #     collection = @collection.truncate
  #     expect(collection.count).to eq 0
  #   end
  # end
  #
  # context "#destroy" do
  #   it "delete a Collection" do
  #     collection = @collection.destroy
  #     expect(collection).to be true
  #   end
  # end
  #
  #   context "#get" do
  #     it "revision" do
  #       expect(@myCollection.revision.class).to be String
  #     end
  #
  #     it "collection" do
  #       expect(@myCollection.rotate).to eq true
  #     end
  #   end
  #
  #   context "#import" do
  #     it "import" do
  #       attributes = ["value", "num", "name"]
  #       values = [["uno",1,"ONE"],["due",2,"TWO"],["tre",3,"THREE"]]
  #       result = @myCollection.import attributes: attributes, values: values
  #       expect(result[:created]).to eq 3
  #     end
  #
  #     it "import single" do
  #       attributes = ["value", "num", "name"]
  #       values = ["uno",1,"ONE"]
  #       result = @myCollection.import attributes: attributes, values: values
  #       expect(result[:created]).to eq 1
  #     end
  #
  #     it "importJSON" do
  #       body = [{value: "uno", num: 1, name: "ONE"}, {value: "due", num: 2, name: "DUE"}]
  #       result = @myCollection.import_json body: body
  #       expect(result[:created]).to eq 2
  #     end
  #   end
  #
  #   context "#export" do
  #     it "export" do
  #       result = @myCollection.export flush: true
  #       expect(result[0].class).to be Arango::Document
  #     end
  #
  #     it "exportNext" do
  #       result = @myCollection.export batch_size: 3, flush: true
  #       result = @myCollection.export_next
  #       expect(result[0].class).to be Arango::Document
  #     end
  #   end
  #
  #   context "#indexes" do
  #     it "indexes" do
  #       expect(@myCollection.indexes[0].class).to be Arango::Index
  #     end
  #
  #     it "create" do
  #       myIndex = @myCollection.index(unique: false, fields: "num", type: "hash").create
  #       expect(myIndex.fields).to eq ["num"]
  #     end
  #   end
end
