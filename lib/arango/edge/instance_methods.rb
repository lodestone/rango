module Arango
  module Edge
    module InstanceMethods

      def initialize(edge, from: nil, to: nil, edge_collection:, ignore_revs: false, wait_for_sync: nil)
        @body = _body_from_arg(edge)
        @changed_body = {}
        @ignore_revs = ignore_revs
        @wait_for_sync = wait_for_sync
        @from_instance = nil
        @to_instance = nil
        send(:collection=, edge_collection)
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

      def revision=(r)
        @changed_body[:_rev] = r
      end

      def to_h
        @body.delete_if{|_,v| v.nil?}
      end

      attr_accessor :ignore_revs, :wait_for_sync
      attr_reader :collection, :graph, :database, :server, :body

      def body=(doc)
        @changed_body = _body_from_arg(doc)
        #set_up_from_or_to("from", result[:_from])
        #set_up_from_or_to("to", result[:_to])
      end

      def collection=(collection)
        satisfy_class?(collection, [Arango::EdgeCollection::Mixin])
        @collection = collection
        @graph = @collection.graph
        @database = @collection.database
        @arango_server = @database.arango_server
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

      def from
        # TODO return instance
        @to_instance ||= getinstancefromgraph
      end

      def from_id
        return @changed_body[:_from] if @changed_body.key?(:_from)
        @body[:_from]
      end

      def from=(vertex)
        vertex = vertex.id if vertex.is_a?(Arango::Vertex::Mixin)
        @from_instance = nil
        @changed_body[:_from] = vertex
      end

      def to
        # TODO return instance
        return @changed_body[:_to] if @changed_body.key?(:_to)
        @body[:_to]
      end

      def to_id
        return @changed_body[:_to] if @changed_body.key?(:_to)
        @body[:_to]
      end

      def to=(vertex)
        vertex = vertex.id if vertex.is_a?(Arango::Vertex::Mixin)
        @to_instance = nil
        @changed_body[:_to] = vertex
      end

      private

      def _body_from_arg(arg)
        body = case arg
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
        raise "Edge is missing a from:" unless body.key?(:_from)
        raise "Edge is missing a to:" unless body.key?(:_to)
      end
    end
  end
end
