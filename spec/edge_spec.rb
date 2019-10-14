require 'spec_helper'

describe Arango::Edge do
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

  it "create a new Edge instance" do
    a = @myCollection.vertex(name: "myA", body: {Hello: "World"}).create
    b = @myCollection.vertex(name: "myB", body: {Hello: "World"}).create
    myEdgeDocument = @myEdgeCollection.edge(from: a, to: b)
    expect(myEdgeDocument.body[:_from]).to eq a.id
  end

  it "create a new Edge instance" do
    a = @collection.document("myA", { Hello: "World" }).create
    b = @collection.document("myB", { Hello: "World" }).create
    edge = @edge_collection.create_edge(from: a, to: b)
    expect(edge.body[:_from]).to eq a.id
  end

  it "create a new Edge" do
    myDoc = @myCollection.create_documents document: [{A: "B", num: 1},
      {C: "D", num: 3}]
    myEdge = @myEdgeCollection.edge(from: myDoc[0].id, to: myDoc[1].id)
    myEdge = myEdge.create
    expect(myEdge.body[:_from]).to eq myDoc[0].id
  end

  it "retrieve Document" do
    myDocument = @myEdge.retrieve
    expect(myDocument.collection.name).to eq "MyEdgeCollection"
  end

  it "replace" do
    a = @myCollection.vertex(body: {Hello: "World"}).create
    b = @myCollection.vertex(body: {Hello: "World!!"}).create
    myDocument = @myEdge.replace body: {_from: a.id, _to: b.id}
    expect(myDocument.body[:_from]).to eq a.id
  end

  it "update" do
    cc = @myCollection.vertex(body: {Hello: "World!!!"}).create
    myDocument = @myEdge.update body: {_to: cc.id}
    expect(myDocument.body[:_to]).to eq cc.id
  end

  it "delete a Document" do
    result = @myEdge.destroy
    expect(result).to eq true
  end
end
