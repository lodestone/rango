module Arango
  module VertexCollection
    module ClassMethods
      def new(name, database: Arango.current_database, graph: nil, type: :document,
              status: nil,
              distribute_shards_like: nil, do_compact: nil, enforce_replication_factor: nil, index_buckets: nil, is_system: false,
              is_volatile: false, journal_size: nil, key_options: nil, number_of_shards: nil, replication_factor: nil, shard_keys: nil,
              sharding_strategy: nil, smart_join_attribute: nil, wait_for_sync: nil, wait_for_sync_replication: nil)
        if type == :document
          Arango::DocumentCollection::Base.new(name, database: database, graph: graph, type: :document,
                                               status: status,
                                               distribute_shards_like: distribute_shards_like, do_compact: do_compact,
                                               enforce_replication_factor: enforce_replication_factor, index_buckets: index_buckets,
                                               is_system: is_system, is_volatile: is_volatile, journal_size: journal_size, key_options: key_options,
                                               number_of_shards: number_of_shards, replication_factor: replication_factor, shard_keys: shard_keys,
                                               sharding_strategy: sharding_strategy, smart_join_attribute: smart_join_attribute,
                                               wait_for_sync: wait_for_sync, wait_for_sync_replication: wait_for_sync_replication)
        elsif type == :edge
          super(name, database: database, graph: graph, type: :document,
                status: status,
                distribute_shards_like: distribute_shards_like, do_compact: do_compact, enforce_replication_factor: enforce_replication_factor,
                index_buckets: index_buckets, is_system: is_system, is_volatile: is_volatile, journal_size: journal_size, key_options: key_options,
                number_of_shards: number_of_shards, replication_factor: replication_factor, shard_keys: shard_keys,
                sharding_strategy: sharding_strategy, smart_join_attribute: smart_join_attribute, wait_for_sync: wait_for_sync,
                wait_for_sync_replication: wait_for_sync_replication)
        end
      end
    end
  end
end
