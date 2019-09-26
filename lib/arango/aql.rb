# === AQL ===

module Arango
  class AQL
    include Arango::Helper::Satisfaction
    include Arango::Helper::Return
    extend Arango::Helper::RequestMethod
    class << self

      # id: the query’s id
      # query: the query string (potentially truncated)
      # bindVars: the bind parameter values used by the query
      # started: the date and time when the query was started
      # runTime: the query’s run time up to the point the list of queries was queried
      # state: the query’s current execution state (as a string)
      # stream: whether or not the query uses a streaming cursor
      def from_result_hash(query_hash)
        new_query_hash = query_hash.transform_keys { |k| k.to_s.underscore.to_sym }
        new_query_hash[:query_id] = query_hash.delete(:id)
        Arango::AQL.new(**new_query_hash)
      end
    end

    def initialize(query:, database:, batch_size: nil, bind_vars: nil, cache: nil, count: nil, fail_on_warning: nil, full_count: nil,
                   intermediate_commit_count: nil, intermediate_commit_size: nil, max_plans: nil, max_transaction_size: nil,
                   max_warning_count: nil, memory_limit: nil, optimizer_rules: nil, profile: nil, satellite_sync_wait: nil,
                   skip_inaccessible_collections: nil, ttl: nil,
                   query_id: nil, run_time: nil, started: nil, state: nil, stream: nil,
                   block: nil, &ruby_block)
      block = ruby_block if block_given?
      satisfy_class?(query, [String])
      @query = query
      @database = database
      @arango_server = database.arango_server

      @block        = block

      @count        = count
      @batch_size   = batch_size
      @cache        = cache
      @memory_limit = memory_limit
      @ttl          = ttl
      @bind_vars    = bind_vars

      @has_more = false
      @id       = nil # cursor id
      @query_id = query_id
      @result   = nil

      @run_time = run_time
      @started = started
      @state = state
      @stream = stream

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

    attr_accessor :batch_size, :bind_vars, :cache, :count, :options, :query, :ttl

    attr_reader :arango_server, :cached, :database, :extra, :id, :id_cache, :optimizer_rules, :result
    attr_reader :run_time, :started, :state, :stream

    def has_more?
      @has_more
    end

    def to_h
      {
        batchSize:   @batch_size,
        bindVars:    @bind_vars,
        cache:       @cache,
        count:       @count,
        database:    @database.name,
        idCache:     @id_cache,
        memoryLimit: @memory_limit,
        options:     @options,
        query:       @query,
        result:      @result,
        ttl:         @ttl
      }.delete_if{|_,v| v.nil?}
    end

    request_method :execute do
      body = {
        batchSize:   @batch_size,
        bindVars:    @bind_vars,
        cache:       @cache,
        count:       @count,
        memoryLimit: @memory_limit,
        options:     @options,
        query:       @query,
        ttl:         @ttl
      }
      { post: "_api/cursor", body: body, block: ->(result) {
        set_instance_vars(result)
        @block ? @block.call(self, result) : self
      }}
    end

    request_method :next do
      if @has_more
        { put: "_api/cursor/#{@id}", block: ->(result) { set_instance_vars(result); self }}
      else
        raise Arango::Error.new err: :no_other_aql_next, data: { hasMore: false }
      end
    end

    request_method :drop do
      { delete: "_api/cursor/#{@id}", block: ->(result) { result.response_code == 200 }}
    end
    alias delete drop
    alias destroy drop
    alias batch_delete batch_drop
    alias batch_destroy batch_drop

    request_method :kill do
      { delete: "_api/query/#{@query_id}", block: ->(result) { result.response_code == 200 }}
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

    def set_option(attrs, name, var_name)
      instance_variable_set("@#{var_name}", attrs)
      if attrs.nil?
        @options.delete(name)
      else
        @options[name] = attrs
      end
    end

    def set_instance_vars(result)
      @cached   = result[:cached]
      @extra    = result[:extra]
      @has_more = result[:hasMore]
      @id       = result[:id]
      @count    = result[:count]
      @result   = result[:result]
    end
  end
end
