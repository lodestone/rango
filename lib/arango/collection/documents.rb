module Arango
  class Collection
    module Documents
      def create_documents(document: [], wait_for_sync: nil, return_new: nil,
                           silent: nil)
        document = [document] unless document.is_a? Array
        document = document.map{|x| return_body(x)}
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
          Arango::Document.new(name: result[:_key], collection: self, body: real_body)
        end
      end

      def exist_document?

      end
      alias document_exist? exist_document?

      def get_document(name: nil, body: {}, rev: nil, from: nil, to: nil)
        Arango::Document.new(name: name, collection: self, body: body, rev: rev,
                             from: from, to: to)
      end
      alias fetch_document get_document
      alias retrieve_document get_document

      def documents(type: "document") # "path", "id", "key"
        @return_document = false
        if type == "document"
          @return_document = true
          type = "key"
        end
        satisfy_category?(type, %w[path id key document])
        body = { type: type, collection: @name }
        result = @database.request("PUT", "_api/simple/all-keys", body: body)

        @has_more_simple = result[:hasMore]
        @id_simple = result[:id]
        return result if return_directly?(result)
        return result[:result] unless @return_document
        if @return_document
          result[:result].map{|key| Arango::Document.new(name: key, collection: self)}
        end
      end

      def insert_document

      end

      def insert_documents

      end

      def replace_document

      end

      def replace_documents(document: {}, wait_for_sync: nil, ignore_revs: nil,
                            return_old: nil, return_new: nil)
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
          Arango::Document.new(name: result[:_key], collection: self, body: real_body)
        end
      end

      def update_document

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
          Arango::Document.new(name: result[:_key], collection: self,
                               body: real_body)
        end
      end

      def destroy_document

      end
      def destroy_documents(document: {}, wait_for_sync: nil, return_old: nil,
                            ignore_revs: nil)
        document.each{|x| x = x.body if x.is_a?(Arango::Document)}
        query = {
          waitForSync: wait_for_sync,
          returnOld:   return_old,
          ignoreRevs:  ignore_revs
        }
        @database.request("DELETE", "_api/document/#{@id}", query: query, body: document)
      end


      def next
        if @has_more_simple
          result = @database.request("PUT", "_api/cursor/#{@id_simple}")
          @has_more_simple = result[:hasMore]
          @id_simple = result[:id]
          return result if return_directly?(result)
          return result[:result] unless @return_document
          if @return_document
            result[:result].map{|key| Arango::Document.new(name: key, collection: self)}
          end
        else
          raise Arango::Error.new err: :no_other_simple_next, data: {hasMoreSimple: @has_more_simple}
        end
      end

      def return_body(x, type=:document)
        satisfy_class?(x, [Hash, Arango::Document, Arango::Edge, Arango::Vertex])
        body = case x
               when Hash
                 x
               when Arango::Edge
                 if type == :vertex
                   raise Arango::Error.new err: :wrong_type_instead_of_expected_one, data:
                                                { expected_value: type, received_value: x.type, wrong_object: x }
                 end
                 x.body
               when Arango::Vertex
                 if type == :edge
                   raise Arango::Error.new err: :wrong_type_instead_of_expected_one, data:
                                                { expected_value: type, received_value: x.type, wrong_object: x }
                 end
                 x.body
               when Arango::Document
                 if (type == :vertex && x.collection.type == :edge)  ||
                   (type == :edge && x.collection.type == :document) ||
                   (type == :edge && x.collection.type == :vertex)
                   raise Arango::Error.new err: :wrong_type_instead_of_expected_one, data:
                                                { expected_value: type, received_value: x.collection.type, wrong_object: x}
                 end
                 x.body
               end
        return body.delete_if{|k,v| v.nil?}
      end
      private :return_body

      def return_id(x)
        satisfy_class?(x, [String, Arango::Document, Arango::Vertex])
        return x.is_a?(String) ? x : x.id
      end
      private :return_id



      def create_edges(document: {}, from:, to:, wait_for_sync: nil, return_new: nil, silent: nil)
        edges = []
        from = [from] unless from.is_a? Array
        to   = [to]   unless to.is_a? Array
        document = [document] unless document.is_a? Array
        document = document.map{|x| return_body(x, :edge)}
        from = from.map{|x| return_id(x)}
        to   = to.map{|x| return_id(x)}
        document.each do |b|
          from.each do |f|
            to.each do |t|
              b[:_from] = f
              b[:_to] = t
              edges << b.clone
            end
          end
        end
        create_documents(document: edges, wait_for_sync: wait_for_sync,
                         return_new: return_new, silent: silent)
      end

      def all_documents(offset: 0, limit: nil, batch_size: nil)
        query = "FOR doc IN @name"
        query << "\n LIMIT @offset, @limit" if limit
        # TODO raise "offset must be used with limit" if offset > 0 && !limit # Arango::Error
        query << "\n RETURN doc"
        aql = Arango::AQL.new(database: @database, query: query, bind_vars: { '@name': @name, '@offset': offset, '@limit': limit })
        aql.size = batch_size if batch_size
        result = aql.execute
        result.result
      end

      # == DOCUMENT ==

      # == SIMPLE ==

      def generic_document_search(url, body, single=false)
        result = @database.request("PUT", url, body: body)
        @returnDocument = true
        @hasMoreSimple = result[:hasMore]
        @idSimple = result[:id]
        return result if return_directly?(result)

        if single
          Arango::Document.new(name: result[:document][:_key], collection: self,
                               body: result[:document])
        else
          result[:result].map{|x| Arango::Document.new(name: x[:_key], collection: self, body: x)}
        end
      end
      private :generic_document_search

      def documents_match(match:, skip: nil, limit: nil, batch_size: nil)
        body = {
          collection: @name,
          example:    match,
          skip:       skip,
          limit:      limit,
          batchSize:  batch_size
        }
        generic_document_search("_api/simple/by-example", body)
      end

      def document_match(match:)
        body = {
          collection: @name,
          example:    match
        }
        generic_document_search("_api/simple/first-example", body, true)
      end

      def documents_by_keys(keys:)
        keys = [keys] unless keys.is_a?(Array)
        keys = keys.map{|x| x.is_a?(Arango::Document) ? x.name : x}
        query = "FOR doc IN @name FILTER doc._key IN @keys RETURN doc"
        aql = Arango::AQL.new(database: @database, query: query, bind_vars: { '@name': @name, '@keys': keys })
        result = aql.execute
        result.result
      end

      def random
        body = { collection:  @name }
        generic_document_search("_api/simple/any", body, true)
      end

      def remove_by_keys(keys:, return_old: nil, silent: nil, wait_for_sync: nil)
        options = {
          returnOld:   return_old,
          silent:      silent,
          waitForSync: wait_for_sync
        }
        options.delete_if{|k,v| v.nil?}
        options = nil if options.empty?
        if keys.is_a? Array
          keys = keys.map{|x| x.is_a?(String) ? x : x.key}
        end
        body = { collection: @name, keys: keys, options: options}
        result = @database.request("PUT", "_api/simple/remove-by-keys", body: body)
        return result if return_directly?(result)
        if return_old == true && silent != true
          result.each do |r|
            Arango::Document.new(name: r[:_key], collection: self, body: r)
          end
        else
          return result
        end
      end

      def remove_match(match:, limit: nil, wait_for_sync: nil)
        options = {
          limit:        limit,
          waitForSync:  wait_for_sync
        }
        options.delete_if{|k,v| v.nil?}
        options = nil if options.empty?
        body = {
          collection:  @name,
          "example"    => match,
          "options"    => options
        }
        @database.request("PUT", "_api/simple/remove-by-example", body: body, key: :deleted)
      end

      def replace_match(match:, newValue:, limit: nil, wait_for_sync: nil)
        options = {
          limit:        limit,
          waitForSync:  wait_for_sync
        }
        options.delete_if{|k,v| v.nil?}
        options = nil if options.empty?
        body = {
          collection: @name,
          example:    match,
          options:    options,
          newValue:   newValue
        }
        @database.request("PUT", "_api/simple/replace-by-example", body: body, key: :replaced)
      end

      def update_match(match:, newValue:, keep_null: nil, merge_objects: nil,
                       limit: nil, wait_for_sync: nil)
        options = {
          keepNull:     keep_null,
          mergeObjects: merge_objects,
          limit:        limit,
          waitForSync:  wait_for_sync
        }
        options.delete_if{|k,v| v.nil?}
        options = nil if options.empty?
        body = {
          collection: @name,
          example:    match,
          options:    options,
          newValue:   newValue
        }
        @database.request("PUT", "_api/simple/update-by-example", body: body, key: :updated)
      end

      # === SIMPLE DEPRECATED ===

      def range(right:, attribute:, limit: nil, closed: true, skip: nil, left:,
                warning: @server.warning)
        warning_deprecated(warning, "range")
        body = {
          right:      right,
          attribute:  attribute,
          collection: @name,
          limit:  limit,
          closed: closed,
          skip:   skip,
          left:   left
        }
        result = @database.request("PUT", "_api/simple/range", body: body)
        return result if return_directly?(result)
        result[:result].map do |x|
          Arango::Document.new(name: x[:_key], collection: self, body: x)
        end
      end

      def distance(longitude:, latitude:, limit: nil, offset: 0)
        query = <<~QUERY
        FOR doc IN @name
         SORT DISTANCE(doc.latitude, doc.longitude, @latitude, @longitude) ASC
        QUERY
        query << "\n LIMIT @offset, @limit" if limit
        query << "\n RETURN doc"
        aql = Arango::AQL.new(database: @database, query: query, bind_vars: { '@name': @name, '@latitude': latitude, '@longitude': longitude,
                                                                              '@offset': offset, '@limit': limit})
        result = aql.execute
        result.result
      end

      def within(distance: nil, longitude:, latitude:, radius:, geo: nil,
                 limit: nil, skip: nil, warning: @server.warning)
        warning_deprecated(warning, "within")
        body = {
          distance:   distance,
          longitude:  longitude,
          collection: @name,
          limit:      limit,
          latitude:   latitude,
          skip:       skip,
          geo:        geo,
          radius:     radius
        }
        result = @database.request("PUT", "_api/simple/within", body: body)
        return result if return_directly?(result)
        result[:result].map do |x|
          Arango::Document.new(name: x[:_key], collection: self, body: x)
        end
      end

      def within_rectangle(longitude1:, latitude1:, longitude2:, latitude2:,
                           geo: nil, limit: nil, skip: nil, warning: @server.warning)
        warning_deprecated(warning, "withinRectangle")
        body = {
          "longitude1": longitude1,
          "latitude1":  latitude1,
          "longitude2": longitude2,
          "latitude2":  latitude2,
          collection: @name,
          limit:      limit,
          skip:       skip,
          geo:        geo,
        }
        result = @database.request("PUT", "_api/simple/within-rectangle", body: body)
        return result if return_directly?(result)
        result[:result].map do |x|
          Arango::Document.new(name: x[:_key], collection: self, body: x)
        end
      end

      def fulltext(attribute:, query:, limit: 0)
        query = "FOR doc IN FULLTEXT(@name, @attribute, @query, @limit) RETURN doc"
        aql = Arango::AQL.new(database: @database, query: query, bind_vars: { '@name': @name, '@attribute': attribute, '@query': query,
                                                                              '@limit': limit })
        result = aql.execute
        result.result
      end

      # === EXPORT ===

      def export(count: nil, restrict: nil, batch_size: nil,
                 flush: nil, flush_wait: nil, limit: nil, ttl: nil)
        query = { collection:  @name }
        body = {
          count:     count,
          restrict:  restrict,
          batchSize: batch_size,
          flush:     flush,
          flushWait: flush_wait,
          limit:     limit,
          ttl:       ttl
        }
        result = @database.request("POST", "_api/export", body: body, query: query)
        return reuslt if @server.async != false
        @countExport   = result[:count]
        @hasMoreExport = result[:hasMore]
        @idExport      = result[:id]
        if return_directly?(result) || result[:result][0].nil? || !result[:result][0].is_a?(Hash) || !result[:result][0].key?(:_key)
          return result[:result]
        else
          return result[:result].map do |x|
            Arango::Document.new(name: x[:_key], collection: self, body: x)
          end
        end
      end

      def export_next
        unless @hasMoreExport
          raise Arango::Error.new err: :no_other_export_next, data: {hasMoreExport:  @hasMoreExport}
        else
          query = { collection:  @name }
          result = @database.request("PUT", "_api/export/#{@idExport}", query: query)
          return result if @server.async != false
          @countExport   = result[:count]
          @hasMoreExport = result[:hasMore]
          @idExport      = result[:id]
          if return_directly?(result) || result[:result][0].nil? || !result[:result][0].is_a?(Hash) || !result[:result][0].key?(:_key)
            return result[:result]
          else
            return result[:result].map do |x|
              Arango::Document.new(name: x[:_key], collection: self, body: x)
            end
          end
        end
      end


      attr_reader :count_export, :has_more_export, :has_more_simple, :id_export, :id_simple
    end
  end
end
