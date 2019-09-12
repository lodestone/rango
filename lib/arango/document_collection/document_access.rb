module Arango
  class DocumentCollection
    module DocumentAccess
      def document_exist?

      end
      alias document_exists? document_exist?

      def document(name: nil, body: {}, rev: nil, from: nil, to: nil)
        Arango::Document.new(name: name, collection: self, body: body, rev: rev,
                             from: from, to: to)
      end

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
    end
  end
end