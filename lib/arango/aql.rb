# === AQL ===

module Arango
  class AQL
    include Arango::Helper::Satisfaction
    include Arango::Helper::Return
    extend Arango::Helper::RequestMethod

    def initialize(query:, database:, count: nil, batch_size: nil, cache: nil,
      memory_limit: nil, ttl: nil, bind_vars: nil, fail_on_warning: nil,
      profile: nil, max_transaction_size: nil, skip_inaccessible_collections: nil,
      max_warning_count: nil, intermediate_commit_count: nil,
      satellite_sync_wait: nil, full_count: nil, intermediate_commit_size: nil,
      optimizer_rules: nil, max_plans: nil, block: nil)
      satisfy_class?(query, [String])
      @query = query
      send(:database=, database)

      @block        = block

      @count        = count
      @batch_size   = batch_size
      @cache        = cache
      @memory_limit = memory_limit
      @ttl          = ttl
      @bind_vars    = bind_vars

      @quantity = nil
      @has_more = false
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

    attr_accessor :database

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
    attr_reader :id, :result, :id_cache, :server, :cached, :extra, :optimizer_rules

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
      }.delete_if{|_,v| v.nil?}
    end

    request_method :execute do
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
      { post: "_api/cursor", body: body, block: ->(result) {
        aql_result = return_aql(result)
        if @block
          block.call(self, aql_result)
        else
          aql_result
        end
      }}
    end

    request_method :next do
      if @has_more
        { put: "_api/cursor/#{@id}", block: ->(result) { return_aql(result) }}
      else
        raise Arango::Error.new err: :no_other_aql_next, data: { hasMore: false }
      end
    end

    request_method :drop do
      { delete: "_api/cursor/#{@id}" }
    end
    alias delete drop
    alias destroy drop
    alias batch_delete batch_drop
    alias batch_destroy batch_drop

    request_method :kill do
      { delete: "_api/query/#{@id}", block: ->(_) { nil }}
    end

# === PROPERTY QUERY ===

    request_method :explain do
      body = {
        query:    @query,
        options:  @options,
        bindVars: @bind_vars
      }
      { post: "_api/explain", body: body, block: ->(result) { result }}
    end

    request_method :parse do
      { post: "_api/query", body: {query: @query} , block: ->(result) { result }}
    end

    private

    def return_aql(result)
      @extra    = result[:extra]
      @cached   = result[:cached]
      @quantity = result[:count]
      @has_more = result[:hasMore]
      @id       = result[:id]
      @result   = result[:result]
      result
    end
  end
end
