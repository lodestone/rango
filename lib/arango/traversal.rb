# === TRAVERSAL ===

module Arango
  class Traversal
    include Arango::Helper::Satisfaction
    include Arango::Helper::Return
    include Arango::Helper::DatabaseAssignment

    def initialize(body: {}, direction: nil, edge_collection: nil, expander: nil, filter: nil, init: nil, item_order: nil, max_depth: nil,
                   max_iterations: nil, min_depth: nil, order: nil, sort: nil, strategy: nil, uniqueness: nil, vertex:, visitor: nil)
      satisfy_category?(direction, ["outbound", "inbound", "any", nil])
      satisfy_category?(item_order, ["forward", "backward", nil])
      satisfy_category?(order, ["preorder", "postorder", "preorder-expander", nil])
      satisfy_category?(strategy, ["depthfirst", "breadthfirst", nil])
      body[:direction]       ||= direction
      body[:edge_collection] ||= edge_collection
      body[:expander]        ||= expander
      body[:filter]          ||= filter
      body[:init]            ||= init
      body[:item_order]      ||= item_order
      body[:max_depth]       ||= max_depth
      body[:max_iterations]  ||= max_iterations
      body[:min_depth]       ||= min_depth
      body[:order]           ||= order
      body[:sort]            ||= sort
      body[:startVertex]     ||= vertex
      body[:strategy]        ||= strategy
      body[:uniqueness]      ||= uniqueness
      body[:visitor]         ||= visitor
      assign_body(body)
      @vertices = nil
      @paths = nil
    end

# === DEFINE ===

    attr_accessor :expander, :filter, :init, :max_depth, :max_iterations, :min_depth, :sort, :uniqueness, :visitor
    attr_reader :body, :collection, :database, :direction, :edge_collection, :graph, :item_order, :order, :paths, :server, :strategy,
                :vertex, :vertices
    alias start_vertex vertex

    def body=(body)
      @body = body
      @direction      = body[:direction] || @direction
      @expander       = body[:expander] || @expander
      @filter         = body[:filter] || @filter
      @init           = body[:init] || @init
      @item_order     = body[:item_order] || @item_order
      @max_depth      = body[:maxDepth] || @max_depth
      @max_iterations = body[:max_iterations] || @max_iterations
      @min_depth      = body[:min_depth] || @min_depth
      @order          = body[:order] || @order
      @sort           = body[:sort] || @sort
      @strategy       = body[:strategy] || @strategy
      @uniqueness     = body[:uniqueness] || @uniqueness
      @visitor       = body[:visitor] || @visitor
      send(:edge_collection=, body[:edge_collection] || @edge_collection)
      send(:start_vertex=, body[:startVertex] || @vertex)
    end
    alias assign_body body=

    def direction=(direction)
      satisfy_category?(direction, ["outbound", "inbound", "any", nil])
      @direction = direction
    end

    def item_order=(itemOrder)
      satisfy_category?(itemOrder, ["forward", "backward", nil])
      @item_order = itemOrder
    end

    def strategy=(strategy)
      satisfy_category?(strategy, ["depthfirst", "breadthfirst", nil])
      @strategy = strategy
    end

    def order=(order)
      satisfy_category?(order, ["preorder", "postorder", "preorder-expander", nil])
      @order = order
    end

    def start_vertex=(vertex)
      case vertex
      when Arango::Edge
      when Arango::Document, Arango::Vertex
        @vertex = vertex
        @collection = @vertex.collection
        @database = @collection.database
        @graph  = @collection.graph
        @server = @database.server
        return
      when String
        if @database.nil?
          raise Arango::Error.new err: :database_undefined_for_traversal
        elsif vertex.include? "/"
          val = vertex.split("/")
          @collection = Arango::Collection.new(database: @database, name: val[0])
          @vertex = Arango::Document.new(collection: @collection, name: val[1])
          return
        end
      end
      raise Arango::Error.new err: :wrong_start_vertex_type
    end
    alias vertex= start_vertex=

    def edge_collection=(collection)
      return nil if collection.nil?
      satisfy_class?(collection, [Arango::Collection, String])
      case collection
      when Arango::Collection
        if collection.type != :edge
          raise Arango::Error.new err: :edge_collection_should_be_of_type_edge
        end
        @edge_collection = collection
      when String
        collection_instance = Arango::Collection.new(name: collection,
          database: @database, type: :edge, graph: @graph)
        @edge_collection = collection_instance
      end
    end

    def in
      @direction = "inbound"
    end

    def out
      @direction = "outbound"
    end

    def any
      @direction = "any"
    end

  # === TO HASH ===

    def to_h
      {
        database: @database.name,
        direction: @direction,
        edgeCollection: @edge_collection&.name,
        expander: @expander,
        filter: @filter,
        graph: @graph&.name,
        idCache: @id_cache,
        init: @init,
        itemOrder: @item_order,
        maxDepth: @max_depth,
        maxiterations: @max_iterations,
        minDepth: @min_depth,
        order: @order,
        paths: @paths&.map do |x|
          {
            edges: x[:edges]&.map{|e| e.id},
            vertices: x[:vertices]&.map{|v| v.id}
          }
        end,
        sort: @sort,
        startVertex: @vertex&.id,
        strategy: @strategy,
        uniqueness: @uniqueness,
        vertices: @vertices&.map{|x| x.id},
        visitor: @visitor
      }.delete_if{|k,v| v.nil?}
    end

  # === EXECUTE ===

    def execute
      body = {
        direction: @direction,
        edgeCollection: @edge_collection&.name,
        expander: @expander,
        filter: @filter,
        graphName: @graph&.name,
        init: @init,
        itemOrder: @item_order,
        maxDepth: @max_depth,
        maxiterations: @max_iterations,
        minDepth: @min_depth,
        order: @order,
        sort: @sort,
        startVertex: @vertex&.id,
        strategy: @strategy,
        uniqueness: @uniqueness,
        visitor: @visitor
      }
      result = @database.request("POST", "_api/traversal", body: body)
      return result if @server.async != false
      @vertices = result[:result][:visited][:vertices].map do |x|
        collection = Arango::Collection.new(name: x[:_id].split("/")[0],
          database:  @database)
        Arango::Document.new(name: x[:_key], collection: collection, body: x)
      end
      @paths = result[:result][:visited][:paths].map do |x|
        {
          edges: x[:edges].map do |e|
            collection_edge = Arango::Collection.new(name: e[:_id].split("/")[0],
              database:  @database, type: :edge)
            Arango::Document.new(name: e[:_key], collection: collection_edge,
              body: e, from: e[:_from], to: e[:_to])
          end,
          vertices: x[:vertices].map do |v|
            collection_vertex = Arango::Collection.new(name: v[:_id].split("/")[0],
              database:  @database)
            Arango::Document.new(name: v[:_key], collection: collection_vertex, body: v)
          end
        }
      end
      return return_directly?(result) ? result : self
    end
  end
end
