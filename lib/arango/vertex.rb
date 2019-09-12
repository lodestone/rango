# === GRAPH VERTEX ===

module Arango
  class Vertex < Arango::Document
    include Arango::Helper::Traversal

    def initialize(name: nil, collection:, body: {}, rev: nil, cache_name: nil)
      assign_collection(collection)
      unless cache_name.nil?
        @cache_name = cache_name
        @server.cache.save(:document, cache_name, self)
      end
      body[:_key] ||= name
      body[:_rev] ||= rev
      body[:_id]  ||= "#{@collection.name}/#{name}" unless name.nil?
      assign_attributes(body)
    end

# === DEFINE ===

    attr_reader :collection, :database, :server, :graph

    def collection=(collection)
      satisfy_class?(collection, [Arango::DocumentCollection])
      if collection.graph.nil?
        raise Arango::Error.new err: :collection_does_not_have_a_graph, data:
          {name_collection: collection.name, graph: nil}
      end
      @collection = collection
      @graph = @collection.graph
      @database = @collection.database
      @server = @database.server
    end
    alias assign_collection collection=

# == GET ==

    def retrieve(if_match: false)
      headers = {}
      headers[:"If-Match"] = @body[:_rev] if if_match
      result = @graph.request("GET", "vertex/#{@collection.name}/#{@body[:_key]}", headers: headers, key: :vertex)
      return_element(result)
    end

# == POST ==

    def create(body: {}, wait_for_sync: nil)
      body = @body.merge(body)
      query = { waitForSync: wait_for_sync }
      result = @graph.request("POST", "vertex/#{@collection.name}", body: body,
        query: query, key: :vertex)
      return result if @server.async != false
      body2 = result.clone
      body = body.merge(body2)
      assign_attributes(body)
      return return_directly?(result) ? result : self
    end

# == PUT ==

    def replace(body: {}, if_match: false, keep_null: nil, wait_for_sync: nil)
      query = {
        waitForSync: wait_for_sync,
        keepNull: keep_null
      }
      headers = {}
      headers[:"If-Match"] = @body[:_rev] if if_match
      result = @graph.request("PUT", "vertex/#{@collection.name}/#{@body[:_key]}",
        body: body, query: query, headers: headers, key: :vertex)
      return result if @server.async != false
      body2 = result.clone
      body = body.merge(body2)
      assign_attributes(body)
      return return_directly?(result) ? result : self
    end

    def update(body: {}, if_match: false, keep_null: nil, wait_for_sync: nil)
      query = { waitForSync: wait_for_sync, keepNull: keep_null }
      headers = {}
      headers[:"If-Match"] = @body[:_rev] if if_match
      result = @graph.request("PATCH", "vertex/#{@collection.name}/#{@body[:_key]}", body: body,
        query: query, headers: headers, key: :vertex)
      return result if @server.async != false
      body2 = result.clone
      body = body.merge(body2)
      body = @body.merge(body)
      assign_attributes(body)
      return return_directly?(result) ? result : self
    end

# === DELETE ===

    def destroy(wait_for_sync: nil, if_match: false)
      query = { waitForSync: wait_for_sync }
      headers = {}
      headers[:"If-Match"] = @body[:_rev] if if_match
      result = @graph.request("DELETE", "vertex/#{@collection.name}/#{@body[:_key]}",
        query: query, headers: headers)
      return_delete(result)
    end

# === WRONG ===

    def from=(arg)
      raise Arango::Error.new err: :you_cannot_assign_from_or_to_to_a_vertex
    end
    alias to= from=
    alias to from=
    alias to_r from=
    alias from_r from=
  end
end
