module Arango
  module Edge
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
            result_proc = ->(b) { b.result.map { |d| Arango::Edge::Base.new(d, collection: collection) }}
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

        Arango.request_class_method(base, :exist?) do |edge, match_rev: nil, collection:|
          body = _body_from_arg(edge)
          raise Arango::Error err: "Edge with key required!" unless body.key?(:_key)
          request = { head: "_api/document/#{collection.name}/#{body[:_key]}" }
          if body.key?(:_key) && body.key?(:_rev) && match_rev == true
            request[:headers] = {'If-Match' => body[:_rev] }
          elsif body.key?(:_key) && body.key?(:_rev) && match_rev == false
            request[:headers] = {'If-None-Match' => body[:_rev] }
          end
          request[:block] = ->(result) do
            case result.response_code
            when 200 then true # edge was found
            when 304 then true # “If-None-Match” header is given and the edge has the same version
            when 412 then true # “If-Match” header is given and the found edge has a different version.
            else
              false
            end
          end
          request
        end

        Arango.request_class_method(base, :create_edges) do |edges, wait_for_sync: nil, collection:|
          edges = [edges] unless edges.is_a? Array
          edges = edges.map{ |d| _body_from_arg(d) }
          query = { returnNew: true }
          query[:waitForSync] = wait_for_sync unless wait_for_sync.nil?
          { post: "_api/document/#{collection.name}", body: edges, query: query, block: ->(result) do
            result.map do |doc|
              Arango::Edge::Base.new(doc[:new], collection: collection)
            end
          end
          }
        end

        Arango.request_class_method(base, :get) do |edge, collection:|
          edge = _body_from_arg(edge)
          if edge.key?(:_key)
            { get: "_api/document/#{collection.name}/#{edge[:_key]}", block: ->(result) { Arango::Edge::Base.new(result, collection: collection) }}
          else
            bind_vars = {}
            query = "FOR doc IN #{collection.name}"
            i = 0
            edge.each do |k,v|
              i += 1
              query << "\n FILTER doc.@key#{i} == @value#{i}"
              bind_vars["key#{i}"] = k.to_s
              bind_vars["value#{i}"] = v
            end
            query << "\n LIMIT 1"
            query << "\n RETURN doc"
            aql = AQL.new(query: query, database: collection.database, bind_vars: bind_vars, block: ->(_, result) do
              Arango::Edge::Base.new(result.result.first, collection: collection) if result.result.first
            end
            )
            aql.request
          end
        end
        alias fetch get
        alias retrieve get
        alias batch_fetch batch_get
        alias batch_retrieve batch_get

        Arango.multi_request_class_method(base, :get_edges) do |edges, collection:|
          edges = [edges] unless edges.is_a? Array
          edges = edges.map{ |d| _body_from_arg(d) }
          requests = []
          result_edges = []
          edges.each do |edge|
            if edge.key?(:_key)
              requests << { get: "_api/document/#{collection.name}/#{edge[:_key]}", block: ->(result) do
                result_edges << Arango::Edge::Base.new(result, collection: collection)
              end
              }
            else
              bind_vars = {}
              query = "FOR doc IN #{collection.name}"
              i = 0
              edge.each do |k,v|
                i += 1
                query << "\n FILTER doc.@key#{i} == @value#{i}"
                bind_vars["key#{i}"] = k.to_s
                bind_vars["value#{i}"] = v
              end
              query << "\n LIMIT 1"
              query << "\n RETURN doc"
              aql = AQL.new(query: query, database: collection.database, bind_vars: bind_vars, block: ->(_, result) do
                result_edges << Arango::Edge::Base.new(result.result.first, collection: collection) if result.result.first
                result_edges
              end
              )
              requests << aql.request
            end
          end
          requests
        end
        alias fetch_edges get_edges
        alias retrieve_edges get_edges
        alias batch_fetch_edges batch_get_edges
        alias batch_retrieve_edges batch_get_edges

        Arango.request_class_method(base, :replace_edges) do |edges, ignore_revs: false, wait_for_sync: nil, collection:|
          edges = [edges] unless edges.is_a? Array
          edges = edges.map{ |d| _body_from_arg(d) }
          query = { returnNew: true, ignoreRevs: ignore_revs }
          query[:waitForSync] = wait_for_sync unless wait_for_sync.nil?
          { put: "_api/document/#{collection.name}", body: edges, query: query, block: ->(result) do
            result.map do |doc|
              Arango::Edge::Base.new(doc[:new], collection: collection)
            end
          end
          }
        end

        Arango.request_class_method(base, :update_edges) do |edges, ignore_revs: false, wait_for_sync: nil, merge_objects: nil, collection:|
          edges = [edges] unless edges.is_a? Array
          edges = edges.map{ |d| _body_from_arg(d) }
          query = { returnNew: true, ignoreRevs: ignore_revs }
          query[:waitForSync] = wait_for_sync unless wait_for_sync.nil?
          query[:mergeObjects] = merge_objects unless merge_objects.nil?
          { patch: "_api/document/#{collection.name}", body: edges, query: query, block: ->(result) do
            result.map do |doc|
              Arango::Edge::Base.new(doc[:new], collection: collection)
            end
          end
          }
        end

        Arango.request_class_method(base, :drop) do |edge, ignore_revs: false, wait_for_sync: nil, collection:|
          edge = _body_from_arg(edge)
          query = { ignoreRevs: ignore_revs }
          query[:waitForSync] = wait_for_sync unless wait_for_sync.nil?
          headers = nil
          headers = { "If-Match": edge[:_rev] } if !ignore_revs && edge.key?(:_rev)
          { delete: "_api/document/#{collection.name}/#{edge[:_key]}", query: query, headers: headers, block: ->(_) { nil }}
        end
        alias delete drop
        alias destroy drop
        alias batch_delete batch_drop
        alias batch_destroy batch_drop

        Arango.request_class_method(base, :drop_edges) do |edges, ignore_revs: false, wait_for_sync: nil, collection:|
          edges = [edges] unless edges.is_a? Array
          edges = edges.map{ |d| _body_from_arg(d) }
          query = { ignoreRevs: ignore_revs }
          query[:waitForSync] = wait_for_sync unless wait_for_sync.nil?
          { delete: "_api/document/#{collection.name}", body: edges, query: query, block: ->(_) { nil }}
        end
        alias delete_edges drop_edges
        alias destroy_edges drop_edges
        alias batch_delete_edges batch_drop_edges
        alias batch_destroy_edges batch_drop_edges

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
          when Arango::Edge then arg.to_h
          when Arango::Result then arg.to_h
          else
            raise "Unknown arg type, must be String, Hash, Arango::Result or Arango::Edge"
          end
        end
      end
    end
  end
end
