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
        if document.key?(:_key)
          { get: "_api/document/#{collection.name}/#{document[:_key]}", block: ->(result) { Arango::Document.new(result, collection: collection) }}
        else
          bind_vars = {}
          query = "FOR doc IN #{collection.name}"
          i = 0
          document.each do |k,v|
            i += 1
            query << "\n FILTER doc.@key#{i} == @value#{i}"
            bind_vars["key#{i}"] = k.to_s
            bind_vars["value#{i}"] = v
          end
          query << "\n LIMIT 1"
          query << "\n RETURN doc"
          aql = AQL.new(query: query, database: collection.database, bind_vars: bind_vars, block: ->(_, result) do
              Arango::Document.new(result.result.first, collection: collection) if result.result.first
            end
          )
          aql.request
        end
      end
      alias fetch get
      alias retrieve get
      alias batch_fetch batch_get
      alias batch_retrieve batch_get

      Arango.multi_request_class_method(Arango::Document, :get_documents) do |documents, collection:|
        documents = [documents] unless documents.is_a? Array
        documents = documents.map{ |d| _body_from_arg(d) }
        requests = []
        result_documents = []
        documents.each do |document|
          if document.key?(:_key)
            requests << { get: "_api/document/#{collection.name}/#{document[:_key]}", block: ->(result) do
                result_documents << Arango::Document.new(result, collection: collection)
              end
            }
          else
            bind_vars = {}
            query = "FOR doc IN #{collection.name}"
            i = 0
            document.each do |k,v|
              i += 1
              query << "\n FILTER doc.@key#{i} == @value#{i}"
              bind_vars["key#{i}"] = k.to_s
              bind_vars["value#{i}"] = v
            end
            query << "\n LIMIT 1"
            query << "\n RETURN doc"
            aql = AQL.new(query: query, database: collection.database, bind_vars: bind_vars, block: ->(_, result) do
              result_documents << Arango::Document.new(result.result.first, collection: collection) if result.result.first
              result_documents
            end
            )
            requests << aql.request
          end
        end
        requests
      end
      alias fetch_documents get_documents
      alias retrieve_documents get_documents
      alias batch_fetch_documents batch_get_documents
      alias batch_retrieve_documents batch_get_documents

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
        query = { ignoreRevs: ignore_revs }
        query[:waitForSync] = wait_for_sync unless wait_for_sync.nil?
        headers = nil
        headers = { "If-Match": document[:_rev] } if !ignore_revs && document.key?(:_rev)
        { delete: "_api/document/#{collection.name}/#{document[:_key]}", query: query, headers: headers, block: ->(_) { nil }}
      end
      alias delete drop
      alias destroy drop
      alias batch_delete batch_drop
      alias batch_destroy batch_drop

      Arango.request_class_method(Arango::Document, :drop_documents) do |documents, ignore_revs: false, wait_for_sync: nil, collection:|
        documents = [documents] unless documents.is_a? Array
        documents = documents.map{ |d| _body_from_arg(d) }
        query = { ignoreRevs: ignore_revs }
        query[:waitForSync] = wait_for_sync unless wait_for_sync.nil?
        { delete: "_api/document/#{collection.name}", body: documents, query: query, block: ->(_) { nil }}
      end
      alias delete_documents drop_documents
      alias destroy_documents drop_documents
      alias batch_delete_documents batch_drop_documents
      alias batch_destroy_documents batch_drop_documents

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

    def initialize(document, collection:, ignore_revs: false, wait_for_sync: nil)
      @body = _body_from_arg(document)
      @changed_body = {}
      @ignore_revs = ignore_revs
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

    attr_accessor :ignore_revs, :wait_for_sync

    attr_reader :collection, :graph, :database, :server, :body

    # todo body= -> replace_body, update_body
    def body=(doc)
      @changed_body = _body_from_arg(doc)
      #set_up_from_or_to("from", result[:_from])
      #set_up_from_or_to("to", result[:_to])
    end

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

    request_method :reload do
      headers = nil
      headers = { "If-Match": @body[:_rev] } if !@ignore_revs && @body.key?(:_rev)
      { get: "_api/document/#{@collection.name}/#{@body[:_key]}", headers: headers,
        block: ->(result) do
          @body = _body_from_arg(result)
          @changed_body = {}
          self
        end
      }
    end
    alias refresh reload
    alias retrieve reload
    alias revert reload
    alias batch_refresh batch_reload
    alias batch_retrieve batch_reload
    alias batch_revert batch_reload

    request_method :same_revision? do
      headers = { "If-Match": @body[:_rev] }
      { head: "_api/document/#{@collection.name}/#{@body[:_key]}", headers: headers, block: ->(result) { result.response_code == 200 }}
    end

    request_method :create do
      query = { returnNew: true }
      query[:waitForSync] = @wait_for_sync unless @wait_for_sync.nil?
      @body = @body.merge(@changed_body)
      @changed_body = {}
      { post: "_api/document/#{@collection.name}", body: @body, query: query,
        block: ->(result) do
          @body.merge!(result[:new])
          self
        end
      }
    end

    request_method :replace do
      query = { returnNew: true, ignoreRevs: @ignore_revs }
      query[:waitForSync] = @wait_for_sync unless @wait_for_sync.nil?
      headers = nil
      body = @changed_body
      body[:_id] = @body[:_id]
      body[:_key] = @body[:_key]
      body[:_rev] = @body[:_rev]
      @body = body
      @changed_body = {}
      headers = { "If-Match": @body[:_rev] } if !@ignore_revs && @body.key?(:_rev)
      { put: "_api/document/#{@collection.name}/#{@body[:_key]}", body: @body, query: query, headers: headers,
        block: ->(result) do
          @body.merge!(result[:new])
          self
        end
      }
    end

    request_method :save do
      query = { returnNew: true, ignoreRevs: @ignore_revs }
      query[:waitForSync] = @wait_for_sync unless @wait_for_sync.nil?
      headers = nil
      headers = { "If-Match": @body[:_rev] } if !@ignore_revs && @body.key?(:_rev)
      changed_body = @changed_body
      @changed_body = {}
      { patch: "_api/document/#{@collection.name}/#{@body[:_key]}", body: changed_body, query: query, headers: headers,
        block: ->(result) do
          @body.merge!(result[:new])
          self
        end
      }
    end
    alias update save
    alias batch_update batch_save

    request_method :drop do
      query = { waitForSync: @wait_for_sync }
      headers = nil
      headers = { "If-Match": @body[:_rev] } if !@ignore_revs && @body.key?(:_rev)
      { delete: "_api/document/#{@collection.name}/#{@body[:_key]}", query: query, headers: headers, block: ->(_) { nil }}
    end
    alias delete drop
    alias destroy drop
    alias batch_delete batch_drop
    alias batch_destroy batch_drop

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
