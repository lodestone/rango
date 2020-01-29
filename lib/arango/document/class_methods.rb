module Arango
  module Document
    module ClassMethods
      def self.extended(base)
        Arango.aql_request_class_method(base, :all) do |offset: 0, limit: nil, batch_size: nil, collection:|
          bind_vars = {}
          query = "FOR doc IN #{collection.name}"
          if limit && offset
            query << "\n LIMIT @offset, @limit"
            bind_vars[:offset] = offset
            bind_vars[:limit] = limit
          end
          raise Arango::Error.new err: "offset must be used with limit" if offset > 0 && !limit
          query << "\n RETURN doc"
          { query: query, bind_vars: bind_vars, batch_size: batch_size, block: -> (aql, result) do
            result_proc = ->(b) { b.result.map { |d| Arango::Document::Base.new(d, collection: collection) }}
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

        Arango.aql_request_class_method(base, :list) do |offset: 0, limit: nil, batch_size: nil, collection:|
          bind_vars = {}
          query = "FOR doc IN #{collection.name}"
          if limit && offset
            query << "\n LIMIT @offset, @limit"
            bind_vars[:offset] = offset
            bind_vars[:limit] = limit
          end
          raise Arango::Error.new err: "offset must be used with limit" if offset > 0 && !limit
          query << "\n RETURN doc._key"
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

        Arango.request_class_method(base, :exist?) do |document, match_rev: nil, collection:|
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

        Arango.request_class_method(base, :create_documents) do |documents, wait_for_sync: nil, collection:|
          documents = [documents] unless documents.is_a? Array
          documents = documents.map{ |d| _body_from_arg(d) }
          query = { returnNew: true }
          query[:waitForSync] = wait_for_sync unless wait_for_sync.nil?
          { post: "_api/document/#{collection.name}", body: documents, query: query, block: ->(result) do
            result.map do |doc|
              Arango::Document::Base.new(doc[:new], collection: collection)
            end
          end
          }
        end

        Arango.request_class_method(base, :get) do |document, collection:|
          document = _body_from_arg(document)
          if document.key?(:_key)
            { get: "_api/document/#{collection.name}/#{document[:_key]}", block: ->(result) { Arango::Document::Base.new(result, collection: collection) }}
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
              Arango::Document::Base.new(result.result.first, collection: collection) if result.result.first
            end
            )
            aql.request
          end
        end
        base.singleton_class.alias_method :fetch, :get
        base.singleton_class.alias_method :retrieve, :get
        base.singleton_class.alias_method :batch_fetch, :batch_get
        base.singleton_class.alias_method :batch_retrieve, :batch_get

        Arango.multi_request_class_method(base, :get_documents) do |documents, collection:|
          documents = [documents] unless documents.is_a? Array
          documents = documents.map{ |d| _body_from_arg(d) }
          requests = []
          result_documents = []
          documents.each do |document|
            if document.key?(:_key)
              requests << { get: "_api/document/#{collection.name}/#{document[:_key]}", block: ->(result) do
                result_documents << Arango::Document::Base.new(result, collection: collection)
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
                result_documents << Arango::Document::Base.new(result.result.first, collection: collection) if result.result.first
                result_documents
              end
              )
              requests << aql.request
            end
          end
          requests
        end
        base.singleton_class.alias_method :fetch_documents, :get_documents
        base.singleton_class.alias_method :retrieve_documents, :get_documents
        base.singleton_class.alias_method :batch_fetch_documents, :batch_get_documents
        base.singleton_class.alias_method :batch_retrieve_documents, :batch_get_documents

        Arango.request_class_method(base, :replace_documents) do |documents, ignore_revs: false, wait_for_sync: nil, collection:|
          documents = [documents] unless documents.is_a? Array
          documents = documents.map{ |d| _body_from_arg(d) }
          query = { returnNew: true, ignoreRevs: ignore_revs }
          query[:waitForSync] = wait_for_sync unless wait_for_sync.nil?
          { put: "_api/document/#{collection.name}", body: documents, query: query, block: ->(result) do
            result.map do |doc|
              Arango::Document::Base.new(doc[:new], collection: collection)
            end
          end
          }
        end

        Arango.request_class_method(base, :update_documents) do |documents, ignore_revs: false, wait_for_sync: nil, merge_objects: nil, collection:|
          documents = [documents] unless documents.is_a? Array
          documents = documents.map{ |d| _body_from_arg(d) }
          query = { returnNew: true, ignoreRevs: ignore_revs }
          query[:waitForSync] = wait_for_sync unless wait_for_sync.nil?
          query[:mergeObjects] = merge_objects unless merge_objects.nil?
          { patch: "_api/document/#{collection.name}", body: documents, query: query, block: ->(result) do
            result.map do |doc|
              Arango::Document::Base.new(doc[:new], collection: collection)
            end
          end
          }
        end

        Arango.request_class_method(base, :drop) do |document, ignore_revs: false, wait_for_sync: nil, collection:|
          document = _body_from_arg(document)
          query = { ignoreRevs: ignore_revs }
          query[:waitForSync] = wait_for_sync unless wait_for_sync.nil?
          headers = nil
          headers = { "If-Match": document[:_rev] } if !ignore_revs && document.key?(:_rev)
          { delete: "_api/document/#{collection.name}/#{document[:_key]}", query: query, headers: headers, block: ->(_) { nil }}
        end
        base.singleton_class.alias_method :delete, :drop
        base.singleton_class.alias_method :destroy, :drop
        base.singleton_class.alias_method :batch_delete, :batch_drop
        base.singleton_class.alias_method :batch_destroy, :batch_drop

        Arango.request_class_method(base, :drop_documents) do |documents, ignore_revs: false, wait_for_sync: nil, collection:|
          documents = [documents] unless documents.is_a? Array
          documents = documents.map{ |d| _body_from_arg(d) }
          query = { ignoreRevs: ignore_revs }
          query[:waitForSync] = wait_for_sync unless wait_for_sync.nil?
          { delete: "_api/document/#{collection.name}", body: documents, query: query, block: ->(_) { nil }}
        end
        base.singleton_class.alias_method :delete_documents, :drop_documents
        base.singleton_class.alias_method :destroy_documents, :drop_documents
        base.singleton_class.alias_method :batch_delete_documents, :batch_drop_documents
        base.singleton_class.alias_method :batch_destroy_documents, :batch_drop_documents

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
          when Arango::Document::Mixin then arg.to_h
          when Arango::Result then arg.to_h
          else
            raise "Unknown arg type, must be String, Hash, Arango::Result or Arango::Document but was #{arg.class}"
          end
        end
      end
    end
  end
end
