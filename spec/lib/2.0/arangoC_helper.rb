require_relative './../../spec_helper'

describe Arango::Collection do
  context "#new" do
    it "create a new instance" do
      myCollection = @myDatabase.collection name: "MyCollection"
      expect(myCollection.name).to eq "MyCollection"
    end

    it "create a new instance with type Edge" do
      myCollection = @myDatabase.collection name: "MyCollection", type: :edge
      expect(myCollection.type).to eq :edge
    end
  end

  context "#create" do
    it "create a new Collection" do
      @myCollection.destroy
      myCollection = @myCollection.create
      expect(myCollection.name).to eq "MyCollection"
    end

    it "create a duplicate Collection" do
      error = nil
      begin
        @myCollection.create
      rescue Arango::ErrorDB => e
        error = e.errorNum
      end
      expect(error.class).to eq Fixnum
    end

    it "create a new Edge Collection" do
      @myEdgeCollection.destroy
      myCollection = @myEdgeCollection.create
      expect(myCollection.type).to eq :edge
    end

    it "create a new Document in the Collection" do
      myDocument = @myCollection.createDocuments document:
        {"Hello": "World", "num": 1}
      expect(myDocument[0].body[:Hello]).to eq "World"
    end

    it "create new Documents in the Collection" do
      myDocument = @myCollection.createDocuments document: [{"Ciao": "Mondo", "num": 1}, {"Hallo": "Welt", "num": 2}]
      expect(myDocument[0].body[:Ciao]).to eq "Mondo"
    end

    it "create a new Edge in the Collection" do
      myDoc = @myCollection.createDocuments document: [{"A": "B", "num": 1}, {"C": "D", "num": 3}]
      myEdge = @myEdgeCollection.createEdges from: myDoc[0].id, to: myDoc[1].id
      expect(myEdge[0].body[:_from]).to eq myDoc[0].id
    end
  end

  context "#info" do
    it "retrieve the Collection" do
      info = @myCollection.retrieve
      expect(info.name).to eq "MyCollection"
    end

    it "properties of the Collection" do
      info = @myCollection.properties
      expect(info[:name]).to eq "MyCollection"
    end

    it "documents in the Collection" do
      info = @myCollection.count
      expect(info).to eq 5
    end

    it "statistics" do
      info = @myCollection.statistics
      expect(info[:cacheInUse]).to eq false
    end

    it "checksum" do
      info = @myCollection.checksum
      expect(info.class).to eq String
    end

    it "list Documents" do
      info = @myCollection.allDocuments
      expect(info.length).to eq 5
    end

    it "search Documents by match" do
      info = @myCollection.documentsMatch match: {"num": 1}
      expect(info.length).to eq 3
    end

    it "search Document by match" do
      info = @myCollection.documentMatch match: {"num": 1}
      expect(info.collection.name).to eq "MyCollection"
    end

    it "search Document by key match" do
      docs = @myCollection.createDocuments document: [{"_key": "ThisIsATest1", "test": "fantastic"}, {"_key": "ThisIsATest2"}]
      result = @myCollection.documentByKeys keys: ["ThisIsATest1", docs[1]]
      expect(result[0].body[:test]).to eq "fantastic"
    end

    it "remove Document by key match" do
      docs = @myCollection.createDocuments document: [{"_key": "ThisIsATest3", "test": "fantastic"}, {"_key": "ThisIsATest4"}]
      result = @myCollection.removeByKeys keys: ["ThisIsATest3", docs[1]]
      expect(result[:removed]).to eq 2
    end

    it "remove Document by match" do
      @myCollection.createDocuments document: [{"_key": "ThisIsATest5", "test": "fantastic"}, {"_key": "ThisIsATest6"}]
      result = @myCollection.removeMatch match: {"test": "fantastic"}
      expect(result).to eq 2
    end

    it "replace Document by match" do
      @myCollection.createDocuments document: {"test": "fantastic", "val": 4}
      result = @myCollection.replaceMatch match: {"test": "fantastic"}, newValue: {"val": 5}
      expect(result).to eq 1
    end

    it "update Document by match" do
      @myCollection.createDocuments document: {"test": "fantastic2", "val": 5}
      result = @myCollection.updateMatch match: {"val": 5}, newValue: {"val": 6}
      expect(result).to eq 2
    end

    it "search random Document" do
      info = @myCollection.random
      expect(info.collection.name).to eq "MyCollection"
    end
  end

  context "#modify" do
    it "load" do
      myCollection = @myCollection.load
      expect(myCollection.name).to eq "MyCollection"
    end

    it "unload" do
      myCollection = @myCollection.unload
      expect(myCollection.name).to eq "MyCollection"
    end

    it "change" do
      myCollection = @myCollection.change waitForSync: true
      expect(myCollection.body[:waitForSync]).to be true
    end

    it "rename" do
      myCollection = @myCollection.rename newName: "MyCollection2"
      expect(myCollection.name).to eq "MyCollection2"
    end
  end

  context "#truncate" do
    it "truncate a Collection" do
      myCollection = @myCollection.truncate
      expect(myCollection.count).to eq 0
    end
  end

  context "#destroy" do
    it "delete a Collection" do
      myCollection = @myCollection.destroy
      expect(myCollection).to be true
    end
  end
end
