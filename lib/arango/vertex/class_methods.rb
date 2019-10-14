module Arango
  module Vertex
    module ClassMethods
      def extended(base)
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
            result_proc = ->(b) { b.result.map { |d| Arango::Vertex::Base.new(d, collection: collection) }}
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

        Arango.request_class_method(base, :exist?) do |vertex, match_rev: nil, collection:|
          body = _body_from_arg(vertex)
          raise Arango::Error err: "Document with key required!" unless body.key?(:_key)
          request = { head: "_api/document/#{collection.name}/#{body[:_key]}" }
          if body.key?(:_key) && body.key?(:_rev) && match_rev == true
            request[:headers] = {'If-Match' => body[:_rev] }
          elsif body.key?(:_key) && body.key?(:_rev) && match_rev == false
            request[:headers] = {'If-None-Match' => body[:_rev] }
          end
          request[:block] = ->(result) do
            case result.response_code
            when 200 then true # vertex was found
            when 304 then true # “If-None-Match” header is given and the vertex has the same version
            when 412 then true # “If-Match” header is given and the found vertex has a different version.
            else
              false
            end
          end
          request
        end

        Arango.request_class_method(base, :create_vertices) do |vertices, wait_for_sync: nil, collection:|
          vertices = [vertices] unless vertices.is_a? Array
          vertices = vertices.map{ |d| _body_from_arg(d) }
          query = { returnNew: true }
          query[:waitForSync] = wait_for_sync unless wait_for_sync.nil?
          { post: "_api/document/#{collection.name}", body: vertices, query: query, block: ->(result) do
            result.map do |doc|
              Arango::Vertex::Base.new(doc[:new], collection: collection)
            end
          end
          }
        end

        Arango.request_class_method(base, :get) do |vertex, collection:|
          vertex = _body_from_arg(vertex)
          if vertex.key?(:_key)
            { get: "_api/document/#{collection.name}/#{vertex[:_key]}", block: ->(result) { Arango::Vertex::Base.new(result, collection: collection) }}
          else
            bind_vars = {}
            query = "FOR doc IN #{collection.name}"
            i = 0
            vertex.each do |k,v|
              i += 1
              query << "\n FILTER doc.@key#{i} == @value#{i}"
              bind_vars["key#{i}"] = k.to_s
              bind_vars["value#{i}"] = v
            end
            query << "\n LIMIT 1"
            query << "\n RETURN doc"
            aql = AQL.new(query: query, database: collection.database, bind_vars: bind_vars, block: ->(_, result) do
              Arango::Vertex::Base.new(result.result.first, collection: collection) if result.result.first
            end
            )
            aql.request
          end
        end
        alias fetch get
        alias retrieve get
        alias batch_fetch batch_get
        alias batch_retrieve batch_get

        Arango.multi_request_class_method(base, :get_vertices) do |vertices, collection:|
          vertices = [vertices] unless vertices.is_a? Array
          vertices = vertices.map{ |d| _body_from_arg(d) }
          requests = []
          result_vertices = []
          vertices.each do |vertex|
            if vertex.key?(:_key)
              requests << { get: "_api/document/#{collection.name}/#{vertex[:_key]}", block: ->(result) do
                result_vertices << Arango::Vertex::Base.new(result, collection: collection)
              end
              }
            else
              bind_vars = {}
              query = "FOR doc IN #{collection.name}"
              i = 0
              vertex.each do |k,v|
                i += 1
                query << "\n FILTER doc.@key#{i} == @value#{i}"
                bind_vars["key#{i}"] = k.to_s
                bind_vars["value#{i}"] = v
              end
              query << "\n LIMIT 1"
              query << "\n RETURN doc"
              aql = AQL.new(query: query, database: collection.database, bind_vars: bind_vars, block: ->(_, result) do
                result_vertices << Arango::Vertex::Base.new(result.result.first, collection: collection) if result.result.first
                result_vertices
              end
              )
              requests << aql.request
            end
          end
          requests
        end
        alias fetch_vertices get_vertices
        alias retrieve_vertices get_vertices
        alias batch_fetch_vertices batch_get_vertices
        alias batch_retrieve_vertices batch_get_vertices

        Arango.request_class_method(base, :replace_vertices) do |vertices, ignore_revs: false, wait_for_sync: nil, collection:|
          vertices = [vertices] unless vertices.is_a? Array
          vertices = vertices.map{ |d| _body_from_arg(d) }
          query = { returnNew: true, ignoreRevs: ignore_revs }
          query[:waitForSync] = wait_for_sync unless wait_for_sync.nil?
          { put: "_api/document/#{collection.name}", body: vertices, query: query, block: ->(result) do
            result.map do |doc|
              Arango::Vertex::Base.new(doc[:new], collection: collection)
            end
          end
          }
        end

        Arango.request_class_method(base, :update_vertices) do |vertices, ignore_revs: false, wait_for_sync: nil, merge_objects: nil, collection:|
          vertices = [vertices] unless vertices.is_a? Array
          vertices = vertices.map{ |d| _body_from_arg(d) }
          query = { returnNew: true, ignoreRevs: ignore_revs }
          query[:waitForSync] = wait_for_sync unless wait_for_sync.nil?
          query[:mergeObjects] = merge_objects unless merge_objects.nil?
          { patch: "_api/document/#{collection.name}", body: vertices, query: query, block: ->(result) do
            result.map do |doc|
              Arango::Vertex::Base.new(doc[:new], collection: collection)
            end
          end
          }
        end

        Arango.request_class_method(base, :drop) do |vertex, ignore_revs: false, wait_for_sync: nil, collection:|
          vertex = _body_from_arg(vertex)
          query = { ignoreRevs: ignore_revs }
          query[:waitForSync] = wait_for_sync unless wait_for_sync.nil?
          headers = nil
          headers = { "If-Match": vertex[:_rev] } if !ignore_revs && vertex.key?(:_rev)
          { delete: "_api/document/#{collection.name}/#{vertex[:_key]}", query: query, headers: headers, block: ->(_) { nil }}
        end
        alias delete drop
        alias destroy drop
        alias batch_delete batch_drop
        alias batch_destroy batch_drop

        Arango.request_class_method(base, :drop_vertices) do |vertices, ignore_revs: false, wait_for_sync: nil, collection:|
          vertices = [vertices] unless vertices.is_a? Array
          vertices = vertices.map{ |d| _body_from_arg(d) }
          query = { ignoreRevs: ignore_revs }
          query[:waitForSync] = wait_for_sync unless wait_for_sync.nil?
          { delete: "_api/document/#{collection.name}", body: vertices, query: query, block: ->(_) { nil }}
        end
        alias delete_vertices drop_vertices
        alias destroy_vertices drop_vertices
        alias batch_delete_vertices batch_drop_vertices
        alias batch_destroy_vertices batch_drop_vertices

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
          when Arango::Vertex::Base. then arg.to_h
          when Arango::Result then arg.to_h
          else
            raise "Unknown arg type, must be String, Hash, Arango::Result or Arango::Vertex::Base."
          end
        end
      end
    end
  end
end
