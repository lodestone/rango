require 'spec_helper'

describe Arango::Edge do
  before :all do
    @server = connect
    begin
      @server.drop_database(name: "DocumentDatabase")
    rescue
    end
    @database = @server.create_database(name: "DocumentDatabase")
  end

  before :each do
    begin
      @database.drop_collection(name: "DocumentCollection")
    rescue
    end
    begin
      @database.drop_collection(name: "EdgeCollection")
    rescue
    end
    @collection = @database.create_collection(name: "DocumentCollection")
    @edge_collection = @database.create_collection(name: "EdgeCollection")
  end

  after :each do
    begin
      @database.drop_collection(name: "DocumentCollection")
    rescue
    end
    begin
      @database.drop_collection(name: "EdgeCollection")
    rescue
    end
  end

  after :all do
    @server.drop_database(name: "DocumentDatabase")
  end

  it "create a new Edge instance" do
    a = @collection.vertex(name: "myA", body: {Hello: "World"}).create
    b = @collection.vertex(name: "myB", body: {Hello: "World"}).create
    myEdgeDocument = @edge_collection.edge(from: a, to: b)
    expect(myEdgeDocument.body[:_from]).to eq a.id
  end

  it "create a new Edge instance" do
    a = @collection.document("myA", { Hello: "World" }).create
    b = @collection.document("myB", { Hello: "World" }).create
    edge = @edge_collection.create_edge(from: a, to: b)
    expect(edge.body[:_from]).to eq a.id
  end

  it "create a new Edge" do
    myDoc = @collection.create_documents document: [{A: "B", num: 1},
      {C: "D", num: 3}]
    myEdge = @edge_collection.edge(from: myDoc[0].id, to: myDoc[1].id)
    myEdge = myEdge.create
    expect(myEdge.body[:_from]).to eq myDoc[0].id
  end

  it "retrieve Document" do
    myDocument = @myEdge.retrieve
    expect(myDocument.collection.name).to eq "MyEdgeCollection"
  end

  it "replace" do
    a = @collection.vertex(body: {Hello: "World"}).create
    b = @collection.vertex(body: {Hello: "World!!"}).create
    myDocument = @myEdge.replace body: {_from: a.id, _to: b.id}
    expect(myDocument.body[:_from]).to eq a.id
  end

  it "update" do
    cc = @collection.vertex(body: {Hello: "World!!!"}).create
    myDocument = @myEdge.update body: {_to: cc.id}
    expect(myDocument.body[:_to]).to eq cc.id
  end

  it "delete a Document" do
    result = @myEdge.destroy
    expect(result).to eq true
  end
end
