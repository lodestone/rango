module Arango
  module Edge
    module ClassMethods
      def self.extended(base)
        Arango.aql_request_class_method(base, :all) do |offset: 0, limit: nil, batch_size: nil, edge_collection:|
          bind_vars = {}
          query = "FOR doc IN #{edge_collection.name}"
          if limit && offset
            query << "\n LIMIT @offset, @limit"
            bind_vars[:offset] = offset
            bind_vars[:limit] = limit
          end
          raise Arango::Error.new err: "offset must be used with limit" if offset > 0 && !limit
          query << "\n RETURN doc"
          { query: query, bind_vars: bind_vars, batch_size: batch_size, block: -> (aql, result) do
            result_proc = ->(b) { b.result.map { |d| Arango::Edge::Base.new(attributes: d, edge_collection: edge_collection) }}
            final_result = result_proc.call(result)
            if aql.has_more?
              edge_collection.instance_variable_set(:@aql, aql)
              edge_collection.instance_variable_set(:@batch_proc, result_proc)
              unless batch_size
                while aql.has_more?
                  final_result += edge_collection.next_batch
                end
              end
            end
            final_result
          end
          }
        end

        Arango.aql_request_class_method(base, :list) do |offset: 0, limit: nil, batch_size: nil, edge_collection:|
          bind_vars = {}
          query = "FOR doc IN #{edge_collection.name}"
          if limit && offset
            query << "\n LIMIT @offset, @limit"
            bind_vars[:offset] = offset
            bind_vars[:limit] = limit
          end
          raise Arango::Error.new err: "offset must be used with limit" if offset > 0 && !limit
          query << "\n RETURN doc._key"
          { database: edge_collection.database, query: query, bind_vars: bind_vars, batch_size: batch_size, block: -> (aql, result) do
            result_proc = ->(b) { b.result }
            final_result = result_proc.call(result)
            if aql.has_more?
              edge_collection.instance_variable_set(:@aql, aql)
              edge_collection.instance_variable_set(:@batch_proc, result_proc)
              unless batch_size
                while aql.has_more?
                  final_result += edge_collection.next_batch
                end
              end
            end
            final_result
          end
          }
        end

        Arango.request_class_method(base, :exists?) do |key: nil, attributes: {}, match_rev: nil, edge_collection:|
          edge = _attributes_from_arg(attributes)
          edge[:_key] = key if key
          raise Arango::Error.new(err: "Edge with key required!") unless edge.key?(:_key)
          request = { head: "_api/document/#{edge_collection.name}/#{edge[:_key]}" }
          if edge.key?(:_key) && edge.key?(:_rev) && match_rev == true
            request[:headers] = {'If-Match' => edge[:_rev] }
          elsif edge.key?(:_key) && edge.key?(:_rev) && match_rev == false
            request[:headers] = {'If-None-Match' => edge[:_rev] }
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

        Arango.request_class_method(base, :create_edges) do |edges, wait_for_sync: nil, edge_collection:|
          edges = [edges] unless edges.is_a? Array
          edges = edges.map{ |d| _attributes_from_arg(d) }
          query = { returnNew: true }
          query[:waitForSync] = wait_for_sync unless wait_for_sync.nil?
          { post: "_api/document/#{edge_collection.name}", body: edges, query: query, block: ->(result) do
            result.map do |doc|
              Arango::Edge::Base.new(attributes: doc[:new], edge_collection: edge_collection)
            end
          end
          }
        end

        Arango.request_class_method(base, :get) do |key: nil, attributes: {}, edge_collection:|
          edge = _attributes_from_arg(attributes)
          edge[:_key] = key if key
          if edge.key?(:_key)
            { get: "_api/document/#{edge_collection.name}/#{edge[:_key]}", block: ->(result) { Arango::Edge::Base.new(attributes: result, edge_collection: edge_collection) }}
          else
            bind_vars = {}
            query = "FOR doc IN #{edge_collection.name}"
            i = 0
            edge.each do |k,v|
              i += 1
              query << "\n FILTER doc.@key#{i} == @value#{i}"
              bind_vars["key#{i}"] = k.to_s
              bind_vars["value#{i}"] = v
            end
            query << "\n LIMIT 1"
            query << "\n RETURN doc"
            aql = AQL.new(query: query, database: edge_collection.database, bind_vars: bind_vars, block: ->(_, result) do
              Arango::Edge::Base.new(attributes: result.result.first, edge_collection: edge_collection) if result.result.first
            end
            )
            aql.request
          end
        end
        base.singleton_class.alias_method :fetch, :get
        base.singleton_class.alias_method :retrieve, :get
        base.singleton_class.alias_method :batch_fetch, :batch_get
        base.singleton_class.alias_method :batch_retrieve, :batch_get

        Arango.multi_request_class_method(base, :get_edges) do |edges, edge_collection:|
          edges = [edges] unless edges.is_a? Array
          edges = edges.map{ |d| _attributes_from_arg(d) }
          requests = []
          result_edges = []
          edges.each do |edge|
            if edge.key?(:_key)
              requests << { get: "_api/document/#{edge_collection.name}/#{edge[:_key]}", block: ->(result) do
                result_edges << Arango::Edge::Base.new(attributes: result, edge_collection: edge_collection)
              end
              }
            else
              bind_vars = {}
              query = "FOR doc IN #{edge_collection.name}"
              i = 0
              edge.each do |k,v|
                i += 1
                query << "\n FILTER doc.@key#{i} == @value#{i}"
                bind_vars["key#{i}"] = k.to_s
                bind_vars["value#{i}"] = v
              end
              query << "\n LIMIT 1"
              query << "\n RETURN doc"
              aql = AQL.new(query: query, database: edge_collection.database, bind_vars: bind_vars, block: ->(_, result) do
                result_edges << Arango::Edge::Base.new(attributes: result.result.first, edge_collection: edge_collection) if result.result.first
                result_edges
              end
              )
              requests << aql.request
            end
          end
          requests
        end
        base.singleton_class.alias_method :fetch_edges, :get_edges
        base.singleton_class.alias_method :retrieve_edges, :get_edges
        base.singleton_class.alias_method :batch_fetch_edges, :batch_get_edges
        base.singleton_class.alias_method :batch_retrieve_edges, :batch_get_edges

        Arango.request_class_method(base, :replace_edges) do |edges, ignore_revs: false, wait_for_sync: nil, edge_collection:|
          edges = [edges] unless edges.is_a? Array
          edges = edges.map{ |d| _attributes_from_arg(d) }
          query = { returnNew: true, ignoreRevs: ignore_revs }
          query[:waitForSync] = wait_for_sync unless wait_for_sync.nil?
          { put: "_api/document/#{edge_collection.name}", body: edges, query: query, block: ->(result) do
            result.map do |doc|
              Arango::Edge::Base.new(attributes: doc[:new], edge_collection: edge_collection)
            end
          end
          }
        end

        Arango.request_class_method(base, :update_edges) do |edges, ignore_revs: false, wait_for_sync: nil, merge_objects: nil, edge_collection:|
          edges = [edges] unless edges.is_a? Array
          edges = edges.map{ |d| _attributes_from_arg(d) }
          query = { returnNew: true, ignoreRevs: ignore_revs }
          query[:waitForSync] = wait_for_sync unless wait_for_sync.nil?
          query[:mergeObjects] = merge_objects unless merge_objects.nil?
          { patch: "_api/document/#{edge_collection.name}", body: edges, query: query, block: ->(result) do
            result.map do |doc|
              Arango::Edge::Base.new(attributes: doc[:new], edge_collection: edge_collection)
            end
          end
          }
        end

        Arango.request_class_method(base, :drop) do |key: nil, attributes: {}, ignore_revs: false, wait_for_sync: nil, edge_collection:|
          edge = _attributes_from_arg(attributes)
          edge[:_key] = key if key
          query = { ignoreRevs: ignore_revs }
          query[:waitForSync] = wait_for_sync unless wait_for_sync.nil?
          headers = nil
          headers = { "If-Match": edge[:_rev] } if !ignore_revs && edge.key?(:_rev)
          { delete: "_api/document/#{edge_collection.name}/#{edge[:_key]}", query: query, headers: headers, block: ->(_) { nil }}
        end
        base.singleton_class.alias_method :delete, :drop
        base.singleton_class.alias_method :destroy, :drop
        base.singleton_class.alias_method :batch_delete, :batch_drop
        base.singleton_class.alias_method :batch_destroy, :batch_drop

        Arango.request_class_method(base, :drop_edges) do |edges, ignore_revs: false, wait_for_sync: nil, edge_collection:|
          edges = [edges] unless edges.is_a? Array
          edges = edges.map{ |d| _attributes_from_arg(d) }
          query = { ignoreRevs: ignore_revs }
          query[:waitForSync] = wait_for_sync unless wait_for_sync.nil?
          { delete: "_api/document/#{edge_collection.name}", body: edges, query: query, block: ->(_) { nil }}
        end
        base.singleton_class.alias_method :delete_edges, :drop_edges
        base.singleton_class.alias_method :destroy_edges, :drop_edges
        base.singleton_class.alias_method :batch_delete_edges, :batch_drop_edges
        base.singleton_class.alias_method :batch_destroy_edges, :batch_drop_edges

        private

        def _attributes_from_arg(arg)
          case arg
          when String then { _key: arg }
          when Hash
            arg.transform_keys!(&:to_sym)
            arg[:_id] = arg.delete(:id) if arg.key?(:id) && !arg.key?(:_id)
            arg[:_key] = arg.delete(:key) if arg.key?(:key) && !arg.key?(:_key)
            arg[:_rev] = arg.delete(:rev) if arg.key?(:rev) && !arg.key?(:_rev)
            arg[:_from] = arg.delete(:from) if arg.key?(:from) && !arg.key?(:_from)
            arg[:_to] = arg.delete(:to) if arg.key?(:to) && !arg.key?(:_to)
            arg.delete_if{|_,v| v.nil?}
            arg
          when Arango::Edge::Mixin then arg.to_h
          when Arango::Result then arg.to_h
          else
            raise "Unknown arg type, must be String, Hash, Arango::Result or Arango::Edge::Mixin."
          end
        end
      end
    end
  end
end
