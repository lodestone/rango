module Arango
  class Collection
    module Indexes
      # === INDEXES ===

      def ensure_hash_index

      end

      def ensure_skip_list_index

      end

      def ensure_geo_index

      end

      def ensure_fulltext_index

      end

      def ensure_persistent_index

      end

      def ensure_ttl_index

      end

      def index(body: {}, id: nil, type: "hash", unique: nil, fields:,
                sparse: nil, geoJson: nil, minLength: nil, deduplicate: nil)
        Arango::Index.new(collection: self, body: body, id: id, type: type,
                          unique: unique, fields: fields, sparse: sparse, geo_json: geoJson,
                          min_length: minLength, deduplicate: deduplicate)
      end

      def indexes
        query = { collection:  @name }
        result = @database.request("GET", "_api/index", query: query)
        return result if return_directly?(result)
        result[:indexes].map do |x|
          Arango::Index.new(body: x, id: x[:id], collection: self,
                            type: x[:type], unique: x[:unique], fields: x[:fields],
                            sparse: x[:sparse])
        end
      end

      def delete_index

      end
    end
  end
end