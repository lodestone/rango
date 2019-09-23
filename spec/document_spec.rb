require 'spec_helper'

describe Arango::Document do
  before :all do
    @server = connect
    begin
      @server.drop_database("DocumentDatabase")
    rescue
    end
    @database = @server.create_database("DocumentDatabase")
  end

  before :each do
    begin
      @database.drop_collection("DocumentCollection")
    rescue
    end
    begin
      @database.drop_collection("EdgeCollection")
    rescue
    end
    @collection = @database.create_collection("DocumentCollection")
    @edge_collection = @database.create_collection("EdgeCollection")
  end

  after :each do
    begin
      @database.drop_collection("DocumentCollection")
    rescue
    end
    begin
      @database.drop_collection("EdgeCollection")
    rescue
    end
  end

  after :all do
    @server.drop_database("DocumentDatabase")
  end

  context "Collection" do
    it "new_document" do
      document = @collection.new_document(test1: 'value', test2: 100)
      expect(document.collection.name).to eq "DocumentCollection"
    end

    it "create_document" do
      document = @collection.create_document(test1: 'value', test2: 100)
      expect(document.collection.name).to eq "DocumentCollection"
    end

    it "create_document with key" do
      document = @collection.create_document(key: "myKEy", test1: 'value', test2: 100)
      expect(document.collection.name).to eq "DocumentCollection"
    end

    it "create_documents" do
      documents = @collection.create_documents([{ test1: 'value', test2: 100 }, { test3: 'value', test4: 100 }])
      expect(documents.size).to eq(2)
      expect(@collection.document_exist?(documents.first)).to be true
      expect(@collection.document_exist?(documents.last)).to be true
      expect(documents.first.collection.name).to eq "DocumentCollection"
    end

    it "create_documents with key" do
      documents = @collection.create_documents([{ key: 'key1', test1: 'value', test2: 100 }, { key: 'key2', test3: 'value', test4: 100 }])
      expect(documents.size).to eq(2)
      expect(@collection.document_exist?(documents.first)).to be true
      expect(@collection.document_exist?(documents.last)).to be true
      expect(documents.first.collection.name).to eq "DocumentCollection"
    end

    it "create_documents by key" do
      documents = @collection.create_documents(['key1', 'key2'])
      expect(documents.size).to eq(2)
      expect(@collection.document_exist?(documents.first)).to be true
      expect(@collection.document_exist?(documents.last)).to be true
      expect(documents.first.collection.name).to eq "DocumentCollection"
    end

    it "all_documents" do
      @collection.create_document(name: 'test1', a: 'a')
      @collection.create_document(name: 'test2', b: 'b')
      documents = @collection.all_documents
      expect(documents.size).to eq 2
    end

    it "all_documents with limits" do
      @collection.create_document(name: 'test1', a: 'a')
      @collection.create_document(name: 'test2', b: 'b')
      documents = @collection.all_documents(limit: 1, offset: 1)
      expect(documents.size).to eq 1
    end

    it "list_documents" do
      @collection.create_document(name: 'test1', a: 'a')
      @collection.create_document(name: 'test2', b: 'b')
      documents = @collection.list_documents
      expect(documents.size).to eq 2
    end

    it "list_documents with limits" do
      @collection.create_document(name: 'test1', a: 'a')
      @collection.create_document(name: 'test2', b: 'b')
      documents = @collection.list_documents(limit: 1, offset: 1)
      expect(documents.size).to eq 1
    end

    it "get_document" do
      @collection.create_document(key: 'superb', test1: 'value', test2: 100)
      document = @collection.get_document('superb')
      expect(document.test1).to eq 'value'
      document = @collection.get_document(key: 'superb')
      expect(document.test1).to eq 'value'
    end

    it "drop_document" do
      document = @collection.create_document
      expect(@collection.list_documents).to include(document.key)
      @collection.drop_document(document.key)
      expect(@collection.list_documents).not_to include(document.key)
    end

    it "exist_document?" do
      expect(@collection.exist_document?('whuahaha')).to be false
      @collection.create_document('whuahaha')
      expect(@collection.exist_document?('whuahaha')).to be true
    end
  end

  context "Arango::Document itself" do
    it "create a new Document instance without global" do
      document = @collection.document "myKey"
      expect(document.collection.name).to eq "DocumentCollection"
    end

    it "create a new Document in the Collection" do
      document = @collection.create_documents document:
        {Hello: "World", num: 1}
      expect(document[0].body[:Hello]).to eq "World"
    end

    it "create_documents" do
      documents = Arango::Document.create_documents([{ test1: 'value', test2: 100 }, { test3: 'value', test4: 100 }], collection: @collection)
      expect(documents.size).to eq(2)
      expect(@collection.document_exist?(documents.first)).to be true
      expect(@collection.document_exist?(documents.last)).to be true
      expect(documents.first.collection.name).to eq "DocumentCollection"
    end

    it "create_documents with key" do
      documents = Arango::Document.create_documents([{ key: 'key1', test1: 'value', test2: 100 }, { key: 'key2', test3: 'value', test4: 100 }], collection: @collection)
      expect(documents.size).to eq(2)
      expect(@collection.document_exist?(documents.first)).to be true
      expect(@collection.document_exist?(documents.last)).to be true
      expect(documents.first.collection.name).to eq "DocumentCollection"
    end

    it "create_documents by key" do
      documents = Arango::Document.create_documents(['key1', 'key2'], collection: @collection)
      expect(documents.size).to eq(2)
      expect(@collection.document_exist?(documents.first)).to be true
      expect(@collection.document_exist?(documents.last)).to be true
      expect(documents.first.collection.name).to eq "DocumentCollection"
    end

    it "create a new Edge in the Collection" do
      myDoc = @collection.create_documents document: [{A: "B", num: 1}, {C: "D", num: 3}]
      myEdge = @edge_collection.create_edges from: myDoc[0].id, to: myDoc[1].id
      expect(myEdge[0].body[:_from]).to eq myDoc[0].id
    end
    it "list Documents" do
      info = collection.all_documents
      expect(info.length).to eq 5
    end

    it "search Documents by match" do
      info = collection.documents_match match: {num: 1}
      expect(info.length).to eq 3
    end

    it "search Document by match" do
      info = collection.document_match match: {num: 1}
      expect(info.collection.name).to eq "DocumentCollection"
    end

    it "search Document by key match" do
      docs = collection.create_documents document: [{_key: "ThisIsATest1", test: "fantastic"}, {_key: "ThisIsATest2"}]
      result = collection.documents_by_keys keys: ["ThisIsATest1", docs[1]]
      expect(result[0].body[:test]).to eq "fantastic"
    end

    it "remove Document by key match" do
      docs = collection.create_documents document: [{_key: "ThisIsATest3", test: "fantastic"}, {_key: "ThisIsATest4"}]
      result = collection.remove_by_keys keys: ["ThisIsATest3", docs[1]]
      expect(result[:removed]).to eq 2
    end

    it "remove Document by match" do
      collection.create_documents document: [{_key: "ThisIsATest5", test: "fantastic"}, {_key: "ThisIsATest6"}]
      result = collection.remove_match match: {test: "fantastic"}
      expect(result).to eq 2
    end

    it "replace Document by match" do
      collection.create_documents document: {test: "fantastic", val: 4}
      result = collection.replace_match match: {test: "fantastic"}, newValue: {val: 5}
      expect(result).to eq 1
    end

    it "update Document by match" do
      collection.create_documents document: {test: "fantastic2", val: 5}
      result = collection.update_match match: {val: 5}, newValue: {val: 6}
      expect(result).to eq 2
    end

    it "search random Document" do
      info = collection.random
      expect(info.collection.name).to eq "DocumentCollection"
    end
  end

  context "#create" do
    it "create a new Document" do
      @document.destroy
      @document.body = {Hello: "World"}
      document = @document.create
      expect(document.body[:Hello]).to eq "World"
    end

    it "create a duplicate Document" do
      error = ""
      begin
        document = @document.create
      rescue Arango::ErrorDB => e
        error = e.error_num
      end
      expect(error).to eq 1210
    end

    it "create a new Edge" do
      myDoc = @collection.create_documents document: [{A: "B", num: 1}, {C: "D", num: 3}]
      myEdge = @edge_collection.document from: myDoc[0].id, to: myDoc[1].id
      myEdge = myEdge.create
      expect(myEdge.body[:_from]).to eq myDoc[0].id
    end
  end

  context "#info" do
    it "retrieve Document" do
      document = @document.retrieve
      expect(document.body[:Hello]).to eq "World"
    end

    it "retrieve Document as Hash" do
      @server.return_output = true
      document = @document.retrieve
      expect(document.class).to be Hash
      @server.return_output = false
      document = @document.retrieve
      expect(document.class).to be Arango::Document
    end

    it "retrieve Edges" do
      @edge_collection.create_edges from: ["MyCollection/myA", "MyCollection/myB"],
                                     to: @document
      myEdges = @document.edges(collection: @edge_collection)
      expect(myEdges.length).to eq 2
    end

    it "going in different directions" do
      document = @document.in("MyEdgeCollection")[0].from.out(@edge_collection)[0].to
      expect(document.id).to eq @document.id
    end
  end

  context "#modify" do
    it "replace" do
      document = @document.replace body: {value: 3}
      expect(document.body[:value]).to eq 3
    end

    it "update" do
      document = @document.update body: {time: 13}
      expect(document.body[:value]).to eq 3
    end
  end

  context "#destroy" do
    it "delete a Document" do
      result = @document.destroy
      expect(result).to eq true
    end
  end
end
