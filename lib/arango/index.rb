  # === INDEXES ===

module Arango
  class Index
    include Arango::Helper::Satisfaction
    include Arango::Helper::DatabaseAssignment
    def self.list(collection:)
      params = { collection: collection.name }
      Arango::Requests::Index::ListAll.execute(server: collection.database.server, params: params)
    end

    def initialize(collection:, fields:, body: {}, cache_name: nil, deduplicate: nil, geo_json: nil, id: nil, min_length: nil, sparse: nil,
                   type: "hash", unique: nil)
      @collection = collection
      assign_database(@collection.database)
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
      body[:geo_json]     ||= geo_json
      body[:min_length]   ||= min_length

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

    def get
      args = {id: @id}
      Arango::Requests::Index::Get(server: @database.server, args: args)
    end

    def create
      body = {
        fields:      @fields,
        type:        @type
      }
      params = { collection: @collection.name }
      case @type.to_sym
      when :hash
        body[:deduplicate] = @deduplicate if @deduplicate
        body[:sparse] = @sparse if @sparse
        body[:unique] = @unique if @unique
      when :fulltext
        body[:min_length] = @min_length if @min_length
      when :general
        body[:deduplicate] = @deduplicate if @deduplicate
        body[:name] = @name if @name
        body[:sparse] = @sparse if @sparse
        body[:unique] = @unique if @unique
      when :geo
        body[:geo_jso] = @geo_json if @geo_json
      when :persistent
        body[:sparse] = @sparse if @sparse
        body[:unique] = @unique if @unique
      when :skiplist
        body[:deduplicate] = @deduplicate if @deduplicate
        body[:sparse] = @sparse if @sparse
        body[:unique] = @unique if @unique
      when :ttl
        body[:expire_after] = @expire_after if @expire_after
      else
        raise "Unknown index type #{@type.to_sym}"
      end
      Arango::Requests::Index::Create.execute(server: @database.server, params: params, body: body)
    end

    def delete
      args = {id: @id}
      Arango::Requests::Index::Delete.execute(server: @database.server, args: args)
    end
  end
end
