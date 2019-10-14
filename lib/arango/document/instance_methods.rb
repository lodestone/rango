module Arango
  module Document
    module InstanceMethods
      def initialize(document, collection:, ignore_revs: false, wait_for_sync: nil)
        @body = _body_from_arg(document)
        @changed_body = {}
        @ignore_revs = ignore_revs
        @wait_for_sync = wait_for_sync
        send(:collection=, collection)
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
        result[:edges].map do |edge|
          collection_name, key = edge[:_id].split("/")
          collection = Arango::Collection.new(collection_name, database: @database, type: :edge)
          Arango::Document::Base.new(edge, collection: collection)
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
end
