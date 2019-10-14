module Arango
  module VertexCollection
    module Vertexs
      def new_vertex(vertex, wait_for_sync: nil)
        Arango::Vertex::Base.new(vertex, collection: self, wait_for_sync: wait_for_sync)
      end

      def create_vertex(vertex, wait_for_sync: nil)
        Arango::Vertex::Base.new(vertex, collection: self, wait_for_sync: wait_for_sync).create
      end
      def batch_create_vertex(vertex, wait_for_sync: nil)
        Arango::Vertex::Base.new(vertex, collection: self, wait_for_sync: wait_for_sync).batch_create
      end

      def create_vertices(array_of_property_hashes, wait_for_sync: nil)
        Arango::Vertex::Base.create_vertices(array_of_property_hashes, collection: self, wait_for_sync: wait_for_sync)
      end
      def batch_create_vertices(array_of_property_hashes, wait_for_sync: nil)
        Arango::Vertex::Base.batch_create_vertices(array_of_property_hashes, collection: self, wait_for_sync: wait_for_sync)
      end

      def exist_vertex?(*args)
        Arango::Vertex::Base.exist?(*args, collection: self)
      end
      def batch_exist_vertex?(*args)
        Arango::Vertex::Base.batch_exist?(*args, collection: self)
      end
      alias vertex_exist? exist_vertex?
      alias batch_vertex_exist? batch_exist_vertex?

      def get_vertex(key)
        Arango::Vertex::Base.get(key, collection: self)
      end
      def batch_get_vertex(key)
        Arango::Vertex::Base.batch_get(key, collection: self)
      end
      alias fetch_vertex get_vertex
      alias retrieve_vertex get_vertex
      alias batch_fetch_vertex batch_get_vertex
      alias batch_retrieve_vertex batch_get_vertex

      def get_vertices(keys)
        Arango::Vertex::Base.get_vertices(keys, collection: self)
      end
      def batch_get_vertices(name)
        Arango::Vertex::Base.batch_get_vertices(name: name, collection: self)
      end
      alias fetch_vertices get_vertices
      alias retrieve_vertices get_vertices
      alias batch_fetch_vertices batch_get_vertices
      alias batch_retrieve_vertices batch_get_vertices

      def all_vertices(offset: 0, limit: nil, batch_size: nil)
        return nil if type == :edge
        Arango::Vertex::Base.all(offset: offset, limit: limit, batch_size: batch_size, collection: self)
      end
      def batch_all_vertices(offset: 0, limit: nil, batch_size: nil)
        return nil if type == :edge
        Arango::Vertex::Base.batch_all(offset: offset, limit: limit, batch_size: batch_size, collection: self)
      end

      def list_vertices(offset: 0, limit: nil, batch_size: nil)
        Arango::Vertex::Base.list(offset: offset, limit: limit, batch_size: batch_size, collection: self)
      end
      def batch_list_vertices(offset: 0, limit: nil, batch_size: nil)
        Arango::Vertex::Base.batch_list(offset: offset, limit: limit, batch_size: batch_size, collection: self)
      end

      def replace_vertex(vertex)
        Arango::Vertex::Base.replace(vertex)
      end
      def batch_replace_vertex(vertex)
        Arango::Vertex::Base.batch_replace(vertex)
      end

      def replace_vertices(vertices_array, wait_for_sync: nil, ignore_revs: nil, return_old: nil, return_new: nil)
        Arango::Vertex::Base.replace_vertices(vertices_array)
      end
      def batch_replace_vertices(vertices_array, wait_for_sync: nil, ignore_revs: nil, return_old: nil, return_new: nil)
        Arango::Vertex::Base.batch_replace_vertices(vertices_array)
      end

      def save_vertex(vertex)
        Arango::Vertex::Base.save(vertex)
      end
      def batch_save_vertex(vertex)
        Arango::Vertex::Base.batch_save(vertex)
      end
      alias update_vertex save_vertex

      def save_vertices(vertices_array, wait_for_sync: nil, ignore_revs: nil)
        Arango::Vertex::Base.save_vertices(vertices_array)
      end
      def batch_save_vertices(vertices_array, wait_for_sync: nil, ignore_revs: nil)
        Arango::Vertex::Base.batch_save_vertices(vertices_array)
      end
      alias update_vertices save_vertices

      def drop_vertex(vertex)
        Arango::Vertex::Base.drop(vertex, collection: self)
      end
      def batch_drop_vertex(vertex)
        Arango::Vertex::Base.batch_drop(vertex, collection: self)
      end
      alias delete_vertex drop_vertex
      alias destroy_vertex drop_vertex
      alias batch_delete_vertex batch_drop_vertex
      alias batch_destroy_vertex batch_drop_vertex

      def drop_vertices(vertices_array)
        Arango::Vertex::Base.drop_vertices(vertices_array, collection: self)
      end
      def batch_drop_vertices(vertices_array)
        Arango::Vertex::Base.batch_drop_vertices(vertices_array, collection: self)
      end
      alias delete_vertices drop_vertices
      alias destroy_vertices drop_vertices
      alias batch_delete_vertices batch_drop_vertices
      alias batch_destroy_vertices batch_drop_vertices
    end
  end
end
