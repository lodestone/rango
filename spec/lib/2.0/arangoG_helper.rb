require_relative './../../spec_helper'

describe Arango::Graph do
  context "#new" do
    it "create a new Graph instance without global" do
      myGraph = @myDatabase.graph name: "MyGraph"
      expect(myGraph.name).to eq "MyGraph"
    end
  end

  context "#create" do
    it "create new graph" do
      @myGraph.destroy
      @myGraph.edge_definitions = []
      @myGraph.orphan_collections = [@myCollection]
      myGraph = @myGraph.create
      expect(myGraph.name).to eq "MyGraph"
    end
  end

  context "#info" do
    it "info graph" do
      myGraph = @myGraph.retrieve
      expect(myGraph.name).to eq "MyGraph"
    end
  end

  context "#manageVertexCollections" do
    it "add VertexCollection" do
      errors = []
      begin
        @myGraph.remove_edge_definition collection: "MyEdgeCollection"
      rescue Arango::Error => e
        errors << e.error_num
      end
      error = ""
      begin
        myGraph = @myGraph.add_vertex_collection collection: "MyCollection"
      rescue Arango::ErrorDB => e
        errors << e.error_num
      end
      @myGraph.remove_vertex_collection collection: "MyCollection"
      myGraph = @myGraph.add_vertex_collection collection: "MyCollection"
      expect([myGraph.orphan_collections[0].name, errors]).to eq ["MyCollection", [1930, 1938]]
    end

    it "retrieve VertexCollection" do
      myGraph = @myGraph.vertex_collections
      expect(myGraph[0].name).to eq "MyCollection"
    end

    it "remove VertexCollection" do
      myGraph = @myGraph.remove_vertex_collection collection: "MyCollection"
      expect(myGraph.orphan_collections[0]).to eq nil
    end
  end

  context "#manageEdgeCollections" do
    it "add EdgeCollection" do
      myGraph = @myGraph.add_edge_definition collection: "MyEdgeCollection", from: "MyCollection", to: @myCollectionB
      expect(myGraph.edge_definitions[0][:from][0].name).to eq "MyCollection"
    end

    it "retrieve EdgeCollection" do
      myGraph = @myGraph.get_edge_collections
      expect(myGraph[0].name).to eq "MyEdgeCollection"
    end

    it "retrieve EdgeCollection" do
      myGraph = @myGraph.edge_definitions
      expect(myGraph[0][:collection].name).to eq "MyEdgeCollection"
    end

    it "replace EdgeCollection" do
      myGraph = @myGraph.replace_edge_definition collection: @myEdgeCollection, from: "MyCollection", to: "MyCollection"
      expect(myGraph.edge_definitions[0][:to][0].name).to eq "MyCollection"
    end

    it "remove EdgeCollection" do
      myGraph = @myGraph.remove_edge_definition collection: "MyEdgeCollection"
      expect(myGraph.edge_definitions[0]).to eq nil
    end
  end

  context "#destroy" do
    it "delete graph" do
      myGraph = @myGraph.destroy
      expect(myGraph).to be true
    end
  end
end
