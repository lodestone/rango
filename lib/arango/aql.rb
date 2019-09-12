# === AQL ===

module Arango
  class AQL
    include Arango::Helper::Satisfaction
    include Arango::Helper::Return
    include Arango::Helper::DatabaseAssignment

    def initialize(query:, database:, count: nil, batch_size: nil, cache: nil,
      memory_limit: nil, ttl: nil, bind_vars: nil, fail_on_warning: nil,
      profile: nil, max_transaction_size: nil, skip_inaccessible_collections: nil,
      max_warning_count: nil, intermediate_commit_count: nil,
      satellite_sync_wait: nil, full_count: nil, intermediate_commit_size: nil,
      optimizer_rules: nil, max_plans: nil)
      satisfy_class?(query, [String])
      @query = query
      assign_database(database)

      @count       = count
      @batch_size  = batch_size
      @cache       = cache
      @memory_limit = memory_limit
      @ttl         = ttl
      @bind_vars   = bind_vars

      @quantity = nil
      @has_more  = false
      @id       = ""
      @result   = []
      @options  = {}
      set_option(fail_on_warning, 'failOnWarning', :fail_on_warning) if fail_on_warning
      set_option(full_count, 'fullCount', :full_count) if full_count
      set_option(intermediate_commit_count, 'intermediateCommitCount', :intermediate_commit_count) if intermediate_commit_count
      set_option(intermediate_commit_size, 'intermediateCommitSize', :intermediate_commit_size) if intermediate_commit_size
      set_option(max_plans, 'maxPlans', :max_plans) if max_plans
      set_option(max_transaction_size, 'maxTransactionSize', :max_transaction_size) if max_transaction_size
      set_option(max_warning_count, 'maxWarningCount', :max_warning_count) if max_warning_count
      set_option(profile, 'profile', :profile) if profile
      set_option(satellite_sync_wait, 'satelliteSyncWait', :satellite_sync_wait) if satellite_sync_wait
      set_option(skip_inaccessible_collections, 'skipInaccessibleCollections', :skip_inaccessible_collections) if skip_inaccessible_collections
      send(:optimizer_rules=, optimizer_rules) if optimizer_rules
    end

# === DEFINE ===
    def optimizer_rules=(attrs)
      @optimizer_rules = attrs
      if attrs.nil?
        @options.delete('optimizer.rules')
      else
        @options['optimizer.rules'] = attrs
      end
    end

    %w[failOnWarning fullCount intermediateCommitCount intermediateCommitSize maxPlans maxTransactionSize maxWarningCount
     profile satelliteSyncWait skipInaccessibleCollections].each do |param_name|
      var_name = param_name.underscore.to_sym
      attr_reader var_name
      define_method("#{var_name}=") do |value|
        set_option(value, param_name, var_name)
      end
    end

    attr_accessor :count, :query, :batch_size, :ttl, :cache, :options, :bind_vars, :quantity
    attr_reader :has_more, :id, :result, :id_cache, :server, :cached, :extra, :optimizer_rules, :database

    def has_more?
      @has_more
    end

    def set_option(attrs, name, var_name)
      instance_variable_set("@#{var_name}", attrs)
      if attrs.nil?
        @options.delete(name)
      else
        @options[name] = attrs
      end
    end
    private :set_option

  # === TO HASH ===

    def to_h
      {
        query:       @query,
        result:      @result,
        count:       @count,
        quantity:    @quantity,
        ttl:         @ttl,
        cache:       @cache,
        batchSize:   @batch_size,
        bindVars:    @bind_vars,
        options:     @options,
        idCache:     @id_cache,
        memoryLimit: @memory_limit,
        database:    @database.name
      }.delete_if{|k,v| v.nil?}
    end

# === REQUEST ===

    def return_aql(result)
      return result if @server.async != false
      @extra    = result[:extra]
      @cached   = result[:cached]
      @quantity = result[:count]
      @has_more = result[:hasMore]
      @id       = result[:id]
      if (result[:result][0].nil? || !result[:result][0].is_a?(Hash) || !result[:result][0].key?(:_key))
        @result = result[:result]
      else
        @result = result[:result].map do |x|
          collection = Arango::DocumentCollection.new(name: x[:_id].split("/")[0], database: @database)
          Arango::Document.new(name: x[:_key], collection: collection, body: x)
        end
      end
      return return_directly?(result) ? result: self
    end
    private :return_aql

  # === EXECUTE QUERY ===

    def execute
      body = {
        query:       @query,
        count:       @count,
        batchSize:   @batch_size,
        ttl:         @ttl,
        cache:       @cache,
        options:     @options,
        bindVars:    @bind_vars,
        memoryLimit: @memory_limit
      }
      result = @database.request("POST", "_api/cursor", body: body)
      return_aql(result)
    end

    def next
      if @has_more
        result = @database.request("PUT", "_api/cursor/#{@id}")
        return_aql(result)
      else
        raise Arango::Error.new err: :no_other_aql_next, data: {hasMore: false}
      end
    end

    def destroy
      @database.request("DELETE", "_api/cursor/#{@id}")
    end

    def kill
      @database.request("DELETE", "_api/query/#{@id}")
    end

# === PROPERTY QUERY ===

    def explain
      body = {
        query:    @query,
        options:  @options,
        bindVars: @bind_vars
      }
      @database.request("POST", "_api/explain", body: body)
    end

    def parse
      @database.request("POST", "_api/query", body: {query: @query})
    end
  end
end
