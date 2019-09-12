module Arango
  class DocumentCollection
    module Basics
      def create

      end
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

      def exist?

      end

      alias exists? exist?

      def info

      end

      def change_property

      end

      def properties
        @database.request("GET", "_api/collection/#{@name}/properties")
      end

      def properties=
        @database.request("GET", "_api/collection/#{@name}/properties")
      end

      def revision
        @database.request("GET", "_api/collection/#{@name}/revision", key: :revision)
      end

      def indexes

      end

      def rename(new_name)
        body = { name: new_name }
        result = @database.request("PUT", "_api/collection/#{@name}/rename", body: body)
        return_element(result)
      end

      def truncate
        result = @database.request("PUT", "_api/collection/#{@name}/truncate")
        return_element(result)
      end

      def drop
        result = @database.request("DELETE", "_api/collection/#{@name}")
        return return_delete(result)
      end
    end
  end
end