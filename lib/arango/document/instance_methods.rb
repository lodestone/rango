module Arango
  module Document
    module InstanceMethods
      extend Arango::Helper::RequestMethod

      def initialize(key: nil, attributes: {}, collection:, ignore_revs: false, wait_for_sync: nil)
        @attributes = _attributes_from_arg(attributes)
        @attributes[:_key] = key if key
        @changed_attributes = {}
        @ignore_revs = ignore_revs
        @wait_for_sync = wait_for_sync
        send(:collection=, collection)
        send(:graph=, collection.graph) if collection.graph
      end

      def id
        i = @changed_attributes[:_id] || @attributes[:_id]
        return i if i
        "#{collection.name}/#{key}"
      end

      def id=(i)
        @changed_attributes[:_id] = i
      end

      def key
        @changed_attributes[:_key] || @attributes[:_key]
      end

      def key=(k)
        @changed_attributes[:_key] = k
      end

      def revision
        @changed_attributes[:_rev] || @attributes[:_rev]
      end

      def revision=(r)
        @changed_attributes[:_rev] = r
      end

      def to_h
        @attributes.delete_if{|_,v| v.nil?}
      end

      def vertex?
        !!@graph
      end

      attr_accessor :ignore_revs, :wait_for_sync
      attr_reader :graph, :collection, :database, :server, :attributes

      def attributes=(doc)
        @changed_attributes = _attributes_from_arg(doc)
        #set_up_from_or_to("from", result[:_from])
        #set_up_from_or_to("to", result[:_to])
      end

      def collection=(collection)
        satisfy_module?(collection, Arango::DocumentCollection::Mixin)
        @collection = collection
        @graph = @collection.graph
        @database = @collection.database
        @arango_server = @database.arango_server
      end

      def graph=(graph)
        satisfy_module?(graph, Arango::Graph::Mixin)
        @graph = graph
        @database = @graph.database
        @arango_server = @graph.arango_server
      end

      def method_missing(name, *args, &block)
        name_s = name.to_s
        set_attr = false
        have_attr = false
        attribute_name_s = name_s.end_with?('=') ? (set_attr = true; name_s.chop) : name_s
        attribute_name_y = attribute_name_s.start_with?('attribute_') ? (have_attr = true; attribute_name_s[9..-1].to_sym) : attribute_name_s.to_sym
        if set_attr
          return @changed_attributes[attribute_name_y] = args[0]
        elsif @changed_attributes.key?(attribute_name_y)
          return @changed_attributes[attribute_name_y]
        elsif @attributes.key?(attribute_name_y)
          return @attributes[attribute_name_y]
        elsif have_attr
          return nil
        end
        super(name, *args, &block)
      end

      request_method :reload do
        # TODO conditional
        if @graph
        headers = {}
        headers[:"If-Match"] = @attributes[:_rev] if if_match
        result = @graph.request("GET", "vertex/#{@collection.name}/#{@attributes[:_key]}", headers: headers, key: :vertex)
        end
        headers = nil
        headers = { "If-Match": @attributes[:_rev] } if !@ignore_revs && @attributes.key?(:_rev)
        { get: "_api/document/#{@collection.name}/#{@attributes[:_key]}", headers: headers,
          block: ->(result) do
            @attributes = _attributes_from_arg(result)
            @changed_attributes = {}
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
        headers = { "If-Match": @attributes[:_rev] }
        { head: "_api/document/#{@collection.name}/#{@attributes[:_key]}", headers: headers, block: ->(result) { result.response_code == 200 }}
      end

      request_method :create do
        # TODO conditional
        # if @graph
        #  @graph.request("POST", "vertex/#{@collection.name}", body: attributes, query: query, key: :vertex)
        # end
        query = { returnNew: true }
        query[:waitForSync] = @wait_for_sync unless @wait_for_sync.nil?
        @attributes = @attributes.merge(@changed_attributes)
        @changed_attributes = {}
        { post: "_api/document/#{@collection.name}", body: @attributes, query: query,
          block: ->(result) do
            @attributes.merge!(result[:new])
            self
          end
        }
      end

      request_method :replace do
        # TODO conditional
        if @graph
          headers[:"If-Match"] = @attributes[:_rev] if if_match
          result = @graph.request("PUT", "vertex/#{@collection.name}/#{@attributes[:_key]}",
                                  body: attributes, query: query, headers: headers, key: :vertex)
        end
        query = { returnNew: true, ignoreRevs: @ignore_revs }
        query[:waitForSync] = @wait_for_sync unless @wait_for_sync.nil?
        headers = nil
        attributes = @changed_attributes
        attributes[:_id] = @attributes[:_id]
        attributes[:_key] = @attributes[:_key]
        attributes[:_rev] = @attributes[:_rev]
        @attributes = attributes
        @changed_attributes = {}
        headers = { "If-Match": @attributes[:_rev] } if !@ignore_revs && @attributes.key?(:_rev)
        { put: "_api/document/#{@collection.name}/#{@attributes[:_key]}", body: @attributes, query: query, headers: headers,
          block: ->(result) do
            @attributes.merge!(result[:new])
            self
          end
        }
      end

      request_method :save do
        # TODO conditional
        if @graph
          headers[:"If-Match"] = @attributes[:_rev] if if_match
          result = @graph.request("PATCH", "vertex/#{@collection.name}/#{@attributes[:_key]}", body: attributes,
                                  query: query, headers: headers, key: :vertex)
        end
        query = { returnNew: true, ignoreRevs: @ignore_revs }
        query[:waitForSync] = @wait_for_sync unless @wait_for_sync.nil?
        headers = nil
        headers = { "If-Match": @attributes[:_rev] } if !@ignore_revs && @attributes.key?(:_rev)
        changed_attributes = @changed_attributes
        @changed_attributes = {}
        { patch: "_api/document/#{@collection.name}/#{@attributes[:_key]}", body: changed_attributes, query: query, headers: headers,
          block: ->(result) do
            @attributes.merge!(result[:new])
            self
          end
        }
      end
      alias update save
      alias batch_update batch_save

      request_method :drop do
        # TODO conditional
        if @graph
          headers[:"If-Match"] = @attributes[:_rev] if if_match
          result = @graph.request("DELETE", "vertex/#{@collection.name}/#{@attributes[:_key]}")
        end
        query = { waitForSync: @wait_for_sync }
        headers = nil
        headers = { "If-Match": @attributes[:_rev] } if !@ignore_revs && @attributes.key?(:_rev)
        { delete: "_api/document/#{@collection.name}/#{@attributes[:_key]}", query: query, headers: headers, block: ->(_) { nil }}
      end
      alias delete drop
      alias destroy drop
      alias batch_delete batch_drop
      alias batch_destroy batch_drop

      private

      def _attributes_from_arg(arg)
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
