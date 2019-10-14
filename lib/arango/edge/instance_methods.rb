module Arango
  module Edge
    module InstanceMethods
      def initialize(name: nil, collection:, body: {}, rev: nil, from: nil,
                     to: nil)
        assign_collection(collection)
        body[:_key]  ||= name
        body[:_rev]  ||= rev
        body[:_from] ||= from
        body[:_to]   ||= to
        body[:_id]   ||= "#{@collection.name}/#{name}" unless name.nil?
        assign_attributes(body)
      end

# === DEFINE ===

      attr_reader :collection, :database, :graph, :server

      def collection=(collection)
        satisfy_class?(collection, [Arango::Collection])
        if collection.graph.nil?
          raise Arango::Error.new err: :collection_does_not_have_a_graph, data:
                                       {name_collection: collection.name, graph: nil}
        end
        @collection = collection
        @graph      = @collection.graph
        @database   = @collection.database
        @server     = @database.server
      end
      alias assign_collection collection=

# == GET ==

      def retrieve(if_match: false)
        headers = {}
        headers[:"If-Match"] = @body[:_rev] if if_match
        result = @graph.request("GET", "edge/#{@collection.name}/#{@body[:_key]}",
                                headers: headers, key: :edge)
        return_element(result)
      end

# == POST ==

      def create(body: {}, wait_for_sync: nil)
        body = @body.merge(body)
        query = {
          waitForSync: wait_for_sync,
          _from:      @body[:_from],
          _to:        @body[:_to]
        }
        result = @graph.request("POST", "edge/#{@collection.name}", body: body,
                                query: query, key: :edge)
        return result if @server.async != false
        body2 = result.clone
        body = body.merge(body2)
        assign_attributes(body)
        return return_directly?(result) ? result : self
      end

# == PUT ==

      def replace(body: {}, wait_for_sync: nil, keep_null: nil, if_match: false)
        query = {
          waitForSync: wait_for_sync,
          keepNull:    keep_null
        }
        headers = {}
        headers[:"If-Match"] = @body[:_rev] if if_match
        result = @graph.request("PUT", "edge/#{@collection.name}/#{@body[:_key]}",
                                body: body, query: query, headers: headers, key: :edge)
        return result if @server.async != false
        body2 = result.clone
        body = body.merge(body2)
        assign_attributes(body)
        return return_directly?(result) ? result : self
      end

      def update(body: {}, wait_for_sync: nil, if_match: false)
        query = {waitForSync: wait_for_sync}
        headers = {}
        headers[:"If-Match"] = @body[:_rev] if if_match
        result = @graph.request("PATCH", "edge/#{@collection.name}/#{@body[:_key]}",
                                body: body, query: query, headers: headers, key: :edge)
        return result if @server.async != false
        body2 = result.clone
        body = body.merge(body2)
        body = @body.merge(body)
        assign_attributes(body)
        return return_directly?(result) ? result : self
      end

# === DELETE ===

      def destroy(wait_for_sync: nil, if_match: false)
        query = {waitForSync: wait_for_sync}
        headers = {}
        headers[:"If-Match"] = @body[:_rev] if if_match
        result = @graph.request("DELETE", "edge/#{@collection.name}/#{@body[:_key]}",
                                query: query, headers: headers)
        return_delete(result)
      end

      def from=(att)
        att = att.id if att.is_a?(Arango::Document)
        assign_attributes({_from: att})
      end

      def to=(att)
        att = att.id if att.is_a?(Arango::Document)
        assign_attributes({_to: att})
      end

      def set_up_from_or_to(attrs, var)
        case var
        when NilClass
          @body[:"_#{attrs}"] = nil
        when String
          unless var.include?("/")
            raise Arango::Error.new err: :attribute_is_not_valid, data:
                                         {attribute: attrs, wrong_value: var}
          end
          @body[:"_#{attrs}"] = var
        when Arango::Document
          @body[:"_#{attrs}"] = var.id
          @from = var if attrs == "from"
          @to   = var if attrs == "to"
        else
          raise Arango::Error.new err: :attribute_is_not_valid, data:
                                       {attribute: attrs, wrong_value: var}
        end
      end
      private :set_up_from_or_to

      def from(string: false)
        return @body[:_from] if string
        @from ||= retrieve_instance_from_and_to(@body[:_from])
        return @from
      end

      def to(string: false)
        return @body[:_to] if string
        @to ||= retrieve_instance_from_and_to(@body[:_to])
        return @to
      end

      def retrieve_instance_from_and_to(var)
        case var
        when NilClass
          return nil
        when String
          collection_name, document_name = var.split("/")
          collection = Arango::Collection.new collection_name, database: @database
          if @graph.nil?
            return Arango::Document::Base.new(document_name, collection: collection)
          else
            collection.graph = @graph
            return Arango::Vertex.new(name: document_name, collection: collection)
          end
        end
      end
      private :retrieve_instance_from_and_to
    end
  end
end
