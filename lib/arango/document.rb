# ==== DOCUMENT ====

module Arango
  class Document
    include Arango::Helper::Satisfaction
    include Arango::Helper::Return
    include Arango::Helper::CollectionAssignment
    include Arango::Helper::Traversal

    extend Arango::Helper::RequestMethod

    class << self
      Arango.aql_request_class_method(Arango::Document, :all) do |offset: 0, limit: nil, batch_size: nil, collection:|
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

      Arango.aql_request_class_method(Arango::Document, :list) do |offset: 0, limit: nil, batch_size: nil, collection:|
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

      Arango.request_class_method(Arango::Document, :exist?) do |document, match_rev: nil, collection:|
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

      Arango.request_class_method(Arango::Document, :create_documents) do |documents, wait_for_sync: nil, collection:|
        documents = [documents] unless documents.is_a? Array
        documents = documents.map{ |d| _body_from_arg(d) }
        query = { returnNew: true }
        query[:waitForSync] = wait_for_sync unless wait_for_sync.nil?
        { post: "_api/document/#{collection.name}", body: documents, query: query, block: ->(result) do
            result.map do |doc|
              Arango::Document.new(doc[:new], collection: collection)
            end
          end
        }
      end

      Arango.request_class_method(Arango::Document, :get) do |document, collection:|
        document = _body_from_arg(document)
        { get: "_api/document/#{collection.name}/#{document[:_key]}", block: ->(result) { Arango::Document.new(result, collection: collection) }}
      end

      Arango.multi_request_class_method(Arango::Document, :get_documents) do |documents, collection:|
        documents = [documents] unless documents.is_a? Array
        documents = documents.map{ |d| _body_from_arg(d) }
        requests = []
        documents.each do |document|
          requests << { get: "_api/document/#{collection.name}/#{document[:_key]}", block: ->(result) do
              result.map do |doc|
                Arango::Document.new(doc, collection: collection)
              end
            end
          }
        end
        requests
      end

      Arango.request_class_method(Arango::Document, :replace_documents) do |documents, ignore_revs: false, wait_for_sync: nil, collection:|
        documents = [documents] unless documents.is_a? Array
        documents = documents.map{ |d| _body_from_arg(d) }
        query = { returnNew: true, ignoreRevs: ignore_revs }
        query[:waitForSync] = wait_for_sync unless wait_for_sync.nil?
        { put: "_api/document/#{collection.name}", body: documents, query: query, block: ->(result) do
            result.map do |doc|
              Arango::Document.new(doc[:new], collection: collection)
            end
          end
        }
      end

      Arango.request_class_method(Arango::Document, :update_documents) do |documents, ignore_revs: false, wait_for_sync: nil, merge_objects: nil, collection:|
        documents = [documents] unless documents.is_a? Array
        documents = documents.map{ |d| _body_from_arg(d) }
        query = { returnNew: true, ignoreRevs: ignore_revs }
        query[:waitForSync] = wait_for_sync unless wait_for_sync.nil?
        query[:mergeObjects] = merge_objects unless merge_objects.nil?
        { patch: "_api/document/#{collection.name}", body: documents, query: query, block: ->(result) do
            result.map do |doc|
              Arango::Document.new(doc[:new], collection: collection)
            end
          end
        }
      end

      Arango.request_class_method(Arango::Document, :drop) do |document, ignore_revs: false, wait_for_sync: nil, collection:|
        document = _body_from_arg(document)
        query = { ignoreRevs:  ignore_revs }
        query[:waitForSync] = wait_for_sync unless wait_for_sync.nil?
        headers = nil
        headers = { "If-Match": document[:_rev] } if !ignore_revs && document.key?(:_rev)
        { delete: "_api/document/#{collection.name}/#{document[:_key]}", query: query, headers: headers, block: ->(_) { nil }}
      end

      Arango.request_class_method(Arango::Document, :drop_documents) do |documents, ignore_revs: false, wait_for_sync: nil, collection:|
        documents = [documents] unless documents.is_a? Array
        documents = documents.map{ |d| _body_from_arg(d) }
        query = { ignoreRevs:  ignore_revs }
        query[:waitForSync] = wait_for_sync unless wait_for_sync.nil?
        { delete: "_api/document/#{collection.name}", body: documents, query: query, block: ->(_) { nil }}
      end

      private

      def _body_from_arg(arg)
        case arg
        when String then { _key: arg }
        when Hash
          arg.transform_keys!(&:to_sym)
          arg[:_id] = arg.delete(:id) if arg.key?(:id) && !arg.key?(:_id)
          arg[:_key] = arg.delete(:key) if arg.key?(:key) && !arg.key?(:_key)
          arg[:_rev] = arg.delete(:rev) if arg.key?(:rev) && !arg.key?(:_rev)
          arg.delete_if{|_,v| v.nil?}
          arg
        when Arango::Document then arg.to_h
        when Arango::Result then arg.to_h
        else
          raise "Unknown arg type, must be String, Hash, Arango::Result or Arango::Document"
        end
      end
    end

    def initialize(document, collection:, wait_for_sync: nil)
      @body = _body_from_arg(document)
      @changed_body = {}
      @wait_for_sync = wait_for_sync
      assign_collection(collection)
    end

    def id
      return @changed_body[:_id] if @changed_body.key?(:_id)
      @body[:_id]
    end

    def id=(i)
      @changed_body[:_id] = i
    end

    def key
      return @changed_body[:_key] if @changed_body.key?(:_key)
      @body[:_key]
    end

    def key=(k)
      @changed_body[:_key] = k
    end

    def revision
      return @changed_body[:_rev] if @changed_body.key?(:_rev)
      @body[:_rev]
    end

    def rev=(r)
      @changed_body[:_rev] = r
    end

    def to_h
      @body.delete_if{|_,v| v.nil?}
    end

    attr_accessor :wait_for_sync

    attr_reader :collection, :graph, :database, :server, :body, :cache_name

    def body=(doc)
      @changed_body = _body_from_arg(doc)
      set_up_from_or_to("from", result[:_from])
      set_up_from_or_to("to", result[:_to])
    end
    alias assign_attributes body=

    def method_missing(name, *args, &block)
      name_s = name.to_s
      set_attr = false
      have_attr = false
      attribute_name_s = name_s.end_with?('=') ? (set_attr = true; name_s.chop) : name_s
      attribute_name_y = attribute_name_s.start_with?('attribute_') ? (have_attr = true; attribute_name_s[9..-1].to_sym) : attribute_name_s.to_sym
      if set_attr
        return @changed_body[attribute_name_y] = args[0]
      elsif @changed_body.key?(attribute_name_y)
        return @changed_body[attribute_name_y]
      elsif @body.key?(attribute_name_y)
        return @body[attribute_name_y]
      elsif have_attr
        return nil
      end
      super(name, *args, &block)
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
          return Arango::Document.new(document_name, collection: collection)
        else
          collection.graph = @graph
          return Arango::Vertex.new(name: document_name, collection: collection)
        end
      end
    end
    private :retrieve_instance_from_and_to

    def retrieve(if_none_match: false, if_match: false)
      headers = {}
      headers[:"If-None-Match"] = @body[:_rev] if if_none_match
      headers[:"If-Match"]      = @body[:_rev] if if_match
      result = @database.request("GET",  "_api/document/#{@body[:_id]}", headers: headers)
      return_element(result)
    end

    def head(if_none_match: false, if_match: false)
      headers = {}
      headers[:"If-None-Match"] = @body[:_rev] if if_none_match
      headers[:"If-Match"]      = @body[:_rev] if if_match
      @database.request("HEAD", "_api/document/#{@body[:_id]}", headers: headers)
    end

    request_method :create do
      query = { returnNew: true }
      query[:waitForSync] = @wait_for_sync unless @wait_for_sync.nil?
      { post: "_api/document/#{@collection.name}", body: @body, query: query, block: ->(result) { @body.merge!(result[:new]); self }}
    end

    request_method :replace do |ignore_revs: false|
      query = { returnNew: true, ignore_revs: ignore_revs }
      query[:waitForSync] = @wait_for_sync unless @wait_for_sync.nil?
      headers = nil
      body = @changed_body
      body[:_id] = @body[:_id]
      body[:_key] = @body[:_key]
      body[:_rev] = @body[:_rev]
      headers = { "If-Match": @body[:_rev] } if !ignore_revs && @body.key?(:_rev)
      { put: "_api/document/#{@body[:_id]}", body: body, query: query, headers: headers, block: ->(result) { @body.merge!(result[:new]); self }}
    end

    request_method :update do |ignore_revs: false|
      query = { returnNew: true, ignore_revs: ignore_revs }
      query[:waitForSync] = @wait_for_sync unless @wait_for_sync.nil?
      headers = nil
      headers = { "If-Match": @body[:_rev] } if !ignore_revs && @body.key?(:_rev)
      { patch: "_api/document/#{@body[:_id]}", body: @changed_body, query: query, headers: headers, block: ->(result) { @body.merge!(result[:new]); self }}
    end

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
        Arango::Document.new(edge, collection: collection)
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
        arg.transform_keys!(&:to_sym)
        arg[:_id] = arg.delete(:id) if arg.key?(:id) && !arg.key?(:_id)
        arg[:_key] = arg.delete(:key) if arg.key?(:key) && !arg.key?(:_key)
        arg[:_rev] = arg.delete(:rev) if arg.key?(:rev) && !arg.key?(:_rev)
        arg.delete_if{|_,v| v.nil?}
        arg
      when Arango::Document then arg.to_h
      when Arango::Result then arg.to_h
      else
        raise "Unknown arg type, must be String, Hash, Arango::Result or Arango::Document"
      end
    end
  end
end
