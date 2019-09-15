require_relative './../../spec_helper'

describe Arango::Document do
  context "#new" do
    it "create a new Document instance without global" do
      myDocument = @myCollection.document name: "myKey"
      expect(myDocument.collection.name).to eq "MyCollection"
    end

    it "create a new Edge instance" do
      a = @myCollection.document(name: "myA", body: {Hello: "World"}).create
      b = @myCollection.document(name: "myB", body: {Hello: "World"}).create
      myEdgeDocument = @myEdgeCollection.document(from: a, to: b)
      expect(myEdgeDocument.body[:_from]).to eq a.id
    end

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
    #   it "list Documents" do
    #     info = collection.all_documents
    #     expect(info.length).to eq 5
    #   end
    #
    #   it "search Documents by match" do
    #     info = collection.documents_match match: {num: 1}
    #     expect(info.length).to eq 3
    #   end
    #
    #   it "search Document by match" do
    #     info = collection.document_match match: {num: 1}
    #     expect(info.collection.name).to eq "MyCollection"
    #   end
    #
    #   it "search Document by key match" do
    #     docs = collection.create_documents document: [{_key: "ThisIsATest1", test: "fantastic"}, {_key: "ThisIsATest2"}]
    #     result = collection.documents_by_keys keys: ["ThisIsATest1", docs[1]]
    #     expect(result[0].body[:test]).to eq "fantastic"
    #   end
    #
    #   it "remove Document by key match" do
    #     docs = collection.create_documents document: [{_key: "ThisIsATest3", test: "fantastic"}, {_key: "ThisIsATest4"}]
    #     result = collection.remove_by_keys keys: ["ThisIsATest3", docs[1]]
    #     expect(result[:removed]).to eq 2
    #   end
    #
    #   it "remove Document by match" do
    #     collection.create_documents document: [{_key: "ThisIsATest5", test: "fantastic"}, {_key: "ThisIsATest6"}]
    #     result = collection.remove_match match: {test: "fantastic"}
    #     expect(result).to eq 2
    #   end
    #
    #   it "replace Document by match" do
    #     collection.create_documents document: {test: "fantastic", val: 4}
    #     result = collection.replace_match match: {test: "fantastic"}, newValue: {val: 5}
    #     expect(result).to eq 1
    #   end
    #
    #   it "update Document by match" do
    #     collection.create_documents document: {test: "fantastic2", val: 5}
    #     result = collection.update_match match: {val: 5}, newValue: {val: 6}
    #     expect(result).to eq 2
    #   end
    #
    #   it "search random Document" do
    #     info = collection.random
    #     expect(info.collection.name).to eq "MyCollection"
    #   end
  end

  context "#create" do
    it "create a new Document" do
      @myDocument.destroy
      @myDocument.body = {Hello: "World"}
      myDocument = @myDocument.create
      expect(myDocument.body[:Hello]).to eq "World"
    end

    it "create a duplicate Document" do
      error = ""
      begin
        myDocument = @myDocument.create
      rescue Arango::ErrorDB => e
        error = e.error_num
      end
      expect(error).to eq 1210
    end

    it "create a new Edge" do
      myDoc = @myCollection.create_documents document: [{A: "B", num: 1}, {C: "D", num: 3}]
      myEdge = @myEdgeCollection.document from: myDoc[0].id, to: myDoc[1].id
      myEdge = myEdge.create
      expect(myEdge.body[:_from]).to eq myDoc[0].id
    end
  end

  context "#info" do
    it "retrieve Document" do
      myDocument = @myDocument.retrieve
      expect(myDocument.body[:Hello]).to eq "World"
    end

    it "retrieve Document as Hash" do
      @server.return_output = true
      myDocument = @myDocument.retrieve
      expect(myDocument.class).to be Hash
      @server.return_output = false
      myDocument = @myDocument.retrieve
      expect(myDocument.class).to be Arango::Document
    end

    it "retrieve Edges" do
      @myEdgeCollection.create_edges from: ["MyCollection/myA", "MyCollection/myB"],
        to: @myDocument
      myEdges = @myDocument.edges(collection: @myEdgeCollection)
      expect(myEdges.length).to eq 2
    end

    it "going in different directions" do
      myDocument = @myDocument.in("MyEdgeCollection")[0].from.out(@myEdgeCollection)[0].to
      expect(myDocument.id).to eq @myDocument.id
    end
  end

  context "#modify" do
    it "replace" do
      myDocument = @myDocument.replace body: {value: 3}
      expect(myDocument.body[:value]).to eq 3
    end

    it "update" do
      myDocument = @myDocument.update body: {time: 13}
      expect(myDocument.body[:value]).to eq 3
    end
  end

  context "#destroy" do
    it "delete a Document" do
      result = @myDocument.destroy
      expect(result).to eq true
    end
  end
end
