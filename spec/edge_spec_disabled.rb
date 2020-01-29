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
    my_edgeDocument = @edge_collection.edge(from: a, to: b)
    expect(my_edgeDocument.body[:_from]).to eq a.id
  end

  it "create a new Edge instance" do
    a = @collection.document("myA", { Hello: "World" }).create
    b = @collection.document("myB", { Hello: "World" }).create
    edge = @edge_collection.create_edge(from: a, to: b)
    expect(edge.body[:_from]).to eq a.id
  end

  it "create a new Edge" do
    my_doc = @collection.create_documents document: [{A: "B", num: 1},
      {C: "D", num: 3}]
    my_edge = @edge_collection.edge(from: my_doc[0].id, to: my_doc[1].id)
    my_edge = my_edge.create
    expect(my_edge.body[:_from]).to eq my_doc[0].id
  end

  it "retrieve Document" do
    my_document = @my_edge.retrieve
    expect(my_document.collection.name).to eq "MyEdgeCollection"
  end

  it "replace" do
    a = @collection.vertex(body: {Hello: "World"}).create
    b = @collection.vertex(body: {Hello: "World!!"}).create
    my_document = @my_edge.replace body: {_from: a.id, _to: b.id}
    expect(my_document.body[:_from]).to eq a.id
  end

  it "update" do
    cc = @collection.vertex(body: {Hello: "World!!!"}).create
    my_document = @my_edge.update body: {_to: cc.id}
    expect(my_document.body[:_to]).to eq cc.id
  end

  it "delete a Document" do
    result = @my_edge.destroy
    expect(result).to eq true
  end
end
