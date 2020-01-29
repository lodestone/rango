module Arango
  module EdgeCollection
    module Edges
      def new_edge(edge, wait_for_sync: nil)
        Arango::Edge::Base.new(edge, collection: self, wait_for_sync: wait_for_sync)
      end

      def create_edge(edge, wait_for_sync: nil)
        Arango::Edge::Base.new(edge, collection: self, wait_for_sync: wait_for_sync).create
      end
      def batch_create_edge(edge, wait_for_sync: nil)
        Arango::Edge::Base.new(edge, collection: self, wait_for_sync: wait_for_sync).batch_create
      end

      def create_edges(array_of_property_hashes, wait_for_sync: nil)
        Arango::Edge::Base.create_edges(array_of_property_hashes, collection: self, wait_for_sync: wait_for_sync)
      end
      def batch_create_edges(array_of_property_hashes, wait_for_sync: nil)
        Arango::Edge::Base.batch_create_edges(array_of_property_hashes, collection: self, wait_for_sync: wait_for_sync)
      end

      def exist_edge?(*args)
        Arango::Edge::Base.exist?(*args, collection: self)
      end
      def batch_exist_edge?(*args)
        Arango::Edge::Base.batch_exist?(*args, collection: self)
      end
      alias edge_exist? exist_edge?
      alias batch_edge_exist? batch_exist_edge?

      def get_edge(key)
        Arango::Edge::Base.get(key, collection: self)
      end
      def batch_get_edge(key)
        Arango::Edge::Base.batch_get(key, collection: self)
      end
      alias fetch_edge get_edge
      alias retrieve_edge get_edge
      alias batch_fetch_edge batch_get_edge
      alias batch_retrieve_edge batch_get_edge

      def get_edges(keys)
        Arango::Edge::Base.get_edges(keys, collection: self)
      end
      def batch_get_edges(name)
        Arango::Edge::Base.batch_get_edges(name: name, collection: self)
      end
      alias fetch_edges get_edges
      alias retrieve_edges get_edges
      alias batch_fetch_edges batch_get_edges
      alias batch_retrieve_edges batch_get_edges

      def all_edges(offset: 0, limit: nil, batch_size: nil)
        return nil if type == :edge
        Arango::Edge::Base.all(offset: offset, limit: limit, batch_size: batch_size, collection: self)
      end
      def batch_all_edges(offset: 0, limit: nil, batch_size: nil)
        return nil if type == :edge
        Arango::Edge::Base.batch_all(offset: offset, limit: limit, batch_size: batch_size, collection: self)
      end

      def list_edges(offset: 0, limit: nil, batch_size: nil)
        Arango::Edge::Base.list(offset: offset, limit: limit, batch_size: batch_size, collection: self)
      end
      def batch_list_edges(offset: 0, limit: nil, batch_size: nil)
        Arango::Edge::Base.batch_list(offset: offset, limit: limit, batch_size: batch_size, collection: self)
      end

      def replace_edge(edge)
        Arango::Edge::Base.replace(edge)
      end
      def batch_replace_edge(edge)
        Arango::Edge::Base.batch_replace(edge)
      end

      def replace_edges(edges_array, wait_for_sync: nil, ignore_revs: nil, return_old: nil, return_new: nil)
        Arango::Edge::Base.replace_edges(edges_array)
      end
      def batch_replace_edges(edges_array, wait_for_sync: nil, ignore_revs: nil, return_old: nil, return_new: nil)
        Arango::Edge::Base.batch_replace_edges(edges_array)
      end

      def save_edge(edge)
        Arango::Edge::Base.save(edge)
      end
      def batch_save_edge(edge)
        Arango::Edge::Base.batch_save(edge)
      end
      alias update_edge save_edge

      def save_edges(edges_array, wait_for_sync: nil, ignore_revs: nil)
        Arango::Edge::Base.save_edges(edges_array)
      end
      def batch_save_edges(edges_array, wait_for_sync: nil, ignore_revs: nil)
        Arango::Edge::Base.batch_save_edges(edges_array)
      end
      alias update_edges save_edges

      def drop_edge(edge)
        Arango::Edge::Base.drop(edge, collection: self)
      end
      def batch_drop_edge(edge)
        Arango::Edge::Base.batch_drop(edge, collection: self)
      end
      alias delete_edge drop_edge
      alias destroy_edge drop_edge
      alias batch_delete_edge batch_drop_edge
      alias batch_destroy_edge batch_drop_edge

      def drop_edges(edges_array)
        Arango::Edge::Base.drop_edges(edges_array, collection: self)
      end
      def batch_drop_edges(edges_array)
        Arango::Edge::Base.batch_drop_edges(edges_array, collection: self)
      end
      alias delete_edges drop_edges
      alias destroy_edges drop_edges
      alias batch_delete_edges batch_drop_edges
      alias batch_destroy_edges batch_drop_edges
    end
  end
end
