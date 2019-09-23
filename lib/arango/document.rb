# ==== DOCUMENT ====

module Arango
  class Document
    include Arango::Helper::Satisfaction
    include Arango::Helper::Return
    include Arango::Helper::CollectionAssignment
    include Arango::Helper::Traversal

    class << self
      Arango.aql_request_class_method Arango::Document, :all do |offset: 0, limit: nil, batch_size: nil, collection:|
        bind_vars = {}
        query = "FOR doc IN #{collection.name}"
        if limit && offset
          query << "\n LIMIT @offset, @limit"
          bind_vars[:offset] = offset
          bind_vars[:limit] = limit
        end
        raise Arango::Error.new err: "offset must be used with limit" if offset > 0 && !limit
        query << "\n RETURN doc"
        # aql = Arango::AQL.new(database: collection.database, query: query, bind_vars: bind_vars, batch_size: batch_size)
        # result = aql.execute
        { query: query, bind_vars: bind_vars, batch_size: batch_size, block: -> (aql, result) do
            result_proc = ->(b) { b.result.map { |d| Arango::Document.new(d, collection: collection) }}
            final_result = result_proc.call(result)
            if aql.has_more?
              collection.instance_variable_set(:@aql, aql)
              collection.instance_variable_set(:@batch_proc, result_proc)
              unless batch_size
                while aql.has_more?
                  final_result += collection.next_batch
                end
              end
            end
            final_result
          end
        }
      end

      Arango.aql_request_class_method Arango::Document, :list do |offset: 0, limit: nil, batch_size: nil, collection:|
        bind_vars = {}
        query = "FOR doc IN #{collection.name}"
        if limit && offset
          query << "\n LIMIT @offset, @limit"
          bind_vars[:offset] = offset
          bind_vars[:limit] = limit
        end
        raise Arango::Error.new err: "offset must be used with limit" if offset > 0 && !limit
        query << "\n RETURN doc._key"
        # aql = Arango::AQL.new(database: collection.database, query: query, bind_vars: bind_vars, batch_size: batch_size)
        # result = aql.execute
        { database: collection.database, query: query, bind_vars: bind_vars, batch_size: batch_size, block: -> (aql, result) do
            result_proc = ->(b) { b.result }
            final_result = result_proc.call(result)
            if aql.has_more?
              collection.instance_variable_set(:@aql, aql)
              collection.instance_variable_set(:@batch_proc, result_proc)
              unless batch_size
                while aql.has_more?
                  final_result += collection.next_batch
                end
              end
            end
            final_result
          end
        }
      end

      Arango.request_class_method Arango::Document, :exist? do |document, match_rev: nil, collection:|
        body = _body_from_arg(document)
        raise Arango::Error err: "Document with key required!" unless body.key?(:_key)
        request = { head: "_api/document/#{collection.name}/#{body[:_key]}" }
        if body.key?(:_key) && body.key?(:_rev) && match_rev == true
          request[:headers] = {'If-Match' => body[:_rev] }
        elsif body.key?(:_key) && body.key?(:_rev) && match_rev == false
          request[:headers] = {'If-None-Match' => body[:_rev] }
        end
        request[:block] = ->(result) do
          case result.response_code
          when 200 then true # document was found
          when 304 then true # “If-None-Match” header is given and the document has the same version
          when 412 then true # “If-Match” header is given and the found document has a different version.
          else
            false
          end
        end
        request
      end

      def create_documents(documents)
        documents = [documents] unless documents.is_a? Array
        documents = documents.map{ |d| _body_from_arg(d) }
        query = {
          waitForSync: wait_for_sync,
          returnNew:   return_new,
          silent:      silent
        }
        results = @database.request("POST", "_api/document/#{@name}", body: document,
                                    query: query)
        return results if return_directly?(results) || silent
        results.map.with_index do |result, index|
          body2 = result.clone
          if return_new
            body2.delete(:new)
            body2 = body2.merge(result[:new])
          end
          real_body = document[index]
          real_body = real_body.merge(body2)
          Arango::Document.new(result[:_key], collection: self, body: real_body)
        end
      end

      def replace_documents
        document.each{|x| x = x.body if x.is_a?(Arango::Document)}
        query = {
          waitForSync: wait_for_sync,
          returnNew:   return_new,
          returnOld:   return_old,
          ignoreRevs:  ignore_revs
        }
        result = @database.request("PUT", "_api/document/#{@name}", body: document,
                                   query: query)
        return results if return_directly?(result)
        results.map.with_index do |result, index|
          body2 = result.clone
          if return_new == true
            body2.delete(:new)
            body2 = body2.merge(result[:new])
          end
          real_body = document[index]
          real_body = real_body.merge(body2)
          Arango::Document.new(result[:_key], collection: self, body: real_body)
        end
      end

      def update_documents(document: {}, wait_for_sync: nil, ignore_revs: nil,
                           return_old: nil, return_new: nil, keep_null: nil, merge_objects: nil)
        document.each{|x| x = x.body if x.is_a?(Arango::Document)}
        query = {
          waitForSync: wait_for_sync,
          returnNew:   return_new,
          returnOld:   return_old,
          ignoreRevs:  ignore_revs,
          keepNull:    keep_null,
          mergeObject: merge_objects
        }
        result = @database.request("PATCH", "_api/document/#{@name}", body: document,
                                   query: query, keep_null: keep_null)
        return results if return_directly?(result)
        results.map.with_index do |result, index|
          body2 = result.clone
          if return_new
            body2.delete(:new)
            body2 = body2.merge(result[:new])
          end
          real_body = document[index]
          real_body = real_body.merge(body2)
          Arango::Document.new(result[:_key], collection: self, body: real_body)
        end
      end

      def drop_documents(document: {}, wait_for_sync: nil, return_old: nil,
                         ignore_revs: nil)
        document.each{|x| x = x.body if x.is_a?(Arango::Document)}
        query = {
          waitForSync: wait_for_sync,
          returnOld:   return_old,
          ignoreRevs:  ignore_revs
        }
        @database.request("DELETE", "_api/document/#{@id}", query: query, body: document)
      end

      private

      def _body_from_arg(arg)
        case arg
        when String then { _key: arg }
        when Hash
          arg[:_id] = arg.delete(:id) if arg.key?(:id) && !arg.key?(:_id)
          arg[:_key] = arg.delete(:key) if arg.key?(:key) && !arg.key?(:_key)
          arg[:_rev] = arg.delete(:rev) if arg.key?(:rev) && !arg.key?(:_rev)
          arg
        when Arango::Document then arg.to_h
        else
          raise "Unknown arg type, must be String, Hash or Arango::Document"
        end
      end
    end

    def initialize(document, collection:, wait_for_sync: nil)
      @body = _body_from_arg(document)
      @wait_for_sync = wait_for_sync
      assign_collection(collection)
    end

    def id
      @body[:_id]
    end

    def id=(i)
      @body[:_id] = i
    end

    def key
      @body[:_key]
    end

    def key=(k)
      @body[:_key] = k
    end

    def revision
      @body[:_rev]
    end

    def rev=(r)
      @body[_:rev] = r
    end

    def to_h
      @body.delete_if{|_,v| v.nil?}
    end

# === DEFINE ==

    attr_reader :collection, :graph, :database, :server, :body, :cache_name

    def body=(result)
      result.delete_if{|k,v| v.nil?}
      @body ||= {}
      # binding.pry if @body[:_key] == "Second_Key"
      hash = {
        _key:  @body[:_key],
        _id:   @body[:_id],
        _rev:  @body[:_rev],
        _from: @body[:_from],
        _to:   @body[:_to]
      }
      @body = hash.merge(result)
      if @body[:_id].nil? && !@body[:_key].nil?
        @body[:_id] = "#{@collection.name}/#{@body[:_key]}"
      end
      set_up_from_or_to("from", result[:_from])
      set_up_from_or_to("to", result[:_to])
      if @server.active_cache && @cache_name.nil? && !@body[:_id].nil?
        @cache_name = "#{@database.name}/#{@body[:_id]}"
        @server.cache.save(:document, @cache_name, self)
      end
    end
    alias assign_attributes body=

# === TO HASH ===

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
          return Arango::Document.new(document_name, collection: collection)
        else
          collection.graph = @graph
          return Arango::Vertex.new(name: document_name, collection: collection)
        end
      end
    end
    private :retrieve_instance_from_and_to

# == GET ==

    def retrieve(if_none_match: false, if_match: false)
      headers = {}
      headers[:"If-None-Match"] = @body[:_rev] if if_none_match
      headers[:"If-Match"]      = @body[:_rev] if if_match
      result = @database.request("GET",  "_api/document/#{@body[:_id]}", headers: headers)
      return_element(result)
    end

# == HEAD ==

    def head(if_none_match: false, if_match: false)
      headers = {}
      headers[:"If-None-Match"] = @body[:_rev] if if_none_match
      headers[:"If-Match"]      = @body[:_rev] if if_match
      @database.request("HEAD", "_api/document/#{@body[:_id]}", headers: headers)
    end

# == POST ==

    def create(body: {}, wait_for_sync: nil, return_new: nil, silent: nil)
      body = @body.merge(body)
      query = {
        waitForSync: wait_for_sync,
        returnNew:   return_new,
        silent:      silent
      }
      result = @database.request("POST", "_api/document/#{@collection.name}", body: body,
        query: query)
      return result if @server.async != false || silent
      body2 = result.clone
      if return_new
        body2.delete(:new)
        body2 = body2.merge(result[:new])
      end
      body = body.merge(body2)
      assign_attributes(body)
      return return_directly?(result) ? result : self
    end

# == PUT ==

    def replace(body: {}, wait_for_sync: nil, ignore_revs: nil, return_old: nil,
      return_new: nil, silent: nil, if_match: false)
      query = {
        waitForSync: wait_for_sync,
        returnNew:   return_new,
        returnOld:   return_old,
        ignoreRevs:  ignore_revs,
        silent:      silent
      }
      headers = {}
      headers[:"If-Match"] = @body[:_rev] if if_match
      result = @database.request("PUT", "_api/document/#{@body[:_id]}", body: body,
        query: query, headers: headers)
      return result if @server.async != false || silent
      body2 = result.clone
      if return_new
        body2.delete(:new)
        body2 = body2.merge(result[:new])
      end
      body = body.merge(body2)
      assign_attributes(body)
      return return_directly?(result) ? result : self
    end

    def update(body: {}, wait_for_sync: nil, ignore_revs: nil,
      return_old: nil, return_new: nil, keep_null: nil,
      merge_objects: nil, silent: nil, if_match: false)
      query = {
        waitForSync:  wait_for_sync,
        returnNew:    return_new,
        returnOld:    return_old,
        ignoreRevs:   ignore_revs,
        keepNull:     keep_null,
        mergeObjects: merge_objects,
        silent:       silent
      }
      headers = {}
      headers[:"If-Match"] = @body[:_rev] if if_match
      result = @database.request("PATCH", "_api/document/#{@body[:_id]}", body: body,
        query: query, headers: headers, keep_null: keep_null)
      return result if @server.async != false || silent
      body2 = result.clone
      if return_new
        body2.delete(:new)
        body2 = body2.merge(result[:new])
      end
      body = body.merge(body2)
      if merge_objects
        @body = @body.merge(body)
      else
        body.each{|key, value| @body[key] = value}
      end
      assign_attributes(@body)
      return return_directly?(result) ? result : self
    end

  # === DELETE ===

    def destroy(wait_for_sync: nil, silent: nil, return_old: nil, if_match: false)
      query = {
        waitForSync: wait_for_sync,
        returnOld:   return_old,
        silent:      silent
      }
      headers = {}
      headers[:"If-Match"] = @body[:_rev] if if_match
      result = @database.request("DELETE", "_api/document/#{@body[:_id]}", query: query,
        headers: headers)
      return result if @server.async != false || silent
      body2 = result.clone
      if return_old
        body2.delete(:old)
        body2 = body2.merge(result[:old])
      else
        body2 = body2.merge(@body)
      end
      return_element(body2)
      return true
    end

  # === EDGE ===

    def edges(collection:, direction: nil)
      satisfy_class?(collection, [Arango::Collection, String])
      collection = collection.is_a?(Arango::Collection) ? collection.name : collection
      query = {
        vertex:    @body[:_id],
        direction: direction
      }
      result = @database.request("GET", "_api/edges/#{collection}", query: query)
      return result if return_directly?(result)
      result[:edges].map do |edge|
        collection_name, key = edge[:_id].split("/")
        collection = Arango::Collection.new(collection_name, database: @database, type: :edge)
        Arango::Document.new(key, body: edge, collection: collection)
      end
    end

    def any(collection)
      edges(collection: collection)
    end

    def out(collection)
      edges(collection: collection, direction: "out")
    end

    def in(collection)
      edges(collection: collection, direction: "in")
    end

    private

    def _body_from_arg(arg)
      case arg
      when String then { _key: arg }
      when Hash
        arg[:_id] = arg.delete(:id) if arg.key?(:id) && !arg.key?(:_id)
        arg[:_key] = arg.delete(:key) if arg.key?(:key) && !arg.key?(:_key)
        arg[:_rev] = arg.delete(:rev) if arg.key?(:rev) && !arg.key?(:_rev)
        arg
      when Arango::Document then arg.to_h
      else
        raise "Unknown arg type, must be String, Hash or Arango::Document"
      end
    end
  end
end
