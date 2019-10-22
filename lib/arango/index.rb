  # === INDEXES ===

module Arango
  class Index
    include Arango::Helper::Satisfaction

    include Arango::Helper::CollectionAssignment

    def initialize(collection:, fields:, body: {}, cache_name: nil, deduplicate: nil, geo_json: nil, id: nil, min_length: nil, sparse: nil,
                   type: "hash", unique: nil)
      assign_collection(collection)
      unless cache_name.nil?
        @cache_name = cache_name
        @server.cache.save(:index, cache_name, self)
      end
      body[:type]        ||= type
      body[:id]          ||= id
      body[:sparse]      ||= sparse
      body[:unique]      ||= unique
      body[:fields]      ||= fields.is_a?(String) ? [fields] : fields
      body[:deduplicate] ||= deduplicate
      body[:geoJson]     ||= geo_json
      body[:minLength]   ||= min_length

      assign_attributes(body)
    end

# === DEFINE ===

    attr_accessor :cache_name, :deduplicate, :fields, :geo_json, :id, :key, :min_length, :sparse, :unique
    attr_reader :collection, :database, :server, :type

    def type=(type)
      satisfy_category?(type, %w[hash skiplist persistent geo fulltext primary])
      @type = type
    end
    alias assign_type type=

    def body=(result)
      @body        = result
      @id          = result[:id] || @id
      @key         = @id&.split("/")&.dig(1)
      @type        = assign_type(result[:type] || @type)
      @unique      = result[:unique]      || @unique
      @fields      = result[:fields]      || @fields
      @sparse      = result[:sparse]      || @sparse
      @geo_json     = result[:geoJson]     || @geo_json
      @min_length   = result[:minLength]   || @min_length
      @deduplicate = result[:deduplicate] || @deduplicate
      if @server.active_cache && @cache_name.nil?
        @cache_name = "#{@database.name}/#{@collection.name}/#{@id}"
        @server.cache.save(:index, @cache_name, self)
      end
    end
    alias assign_attributes body=

# === DEFINE ===

    def to_h
      {
        key: @key,
        id: @id,
        body: @body,
        type: @type,
        sparse: @sparse,
        unique: @unique,
        fields: @fields,
        idCache: @idCache,
        geoJson: @geo_json,
        minLength: @min_length,
        deduplicate: @deduplicate,
        collection: @collection.name
      }.delete_if{|k,v| v.nil?}
    end

# === COMMANDS ===

    def retrieve
      result = @database.request("GET", "_api/index/#{@id}")
      return_element(result)
    end

    def create
      body = {
        fields:      @fields,
        unique:      @unique,
        type:        @type,
        id:          @id,
        geoJson:     @geo_json,
        minLength:   @min_length,
        deduplicate: @deduplicate
      }
      query = { collection: @collection.name }
      result = @database.request("POST", "_api/index", body: body, query: query)
      return_element(result)
    end

    def destroy
      result = @database.request("DELETE", "_api/index/#{@id}")
      return_delete(result)
    end
  end
end
