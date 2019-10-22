module Arango
  class Database
    module GraphAccess
      def all_graphs
        Arango::Graph.all(database: self)
      end
      def batch_all_graps(exclude_system: true)
        Arango::Graph.batch_all(exclude_system: exclude_system, database: self)
      end

      # TODO issmart, edgedefinitions, waitforsync, options
      def create_graph(name)
        Arango::Graph.new(name, database: self).create
      end
      def batch_create_graph(name, type: :document)
        Arango::Graph.new(name, type: type, database: self).batch_create
      end

      def get_graph(name)
        Arango::Graph.get(name, database: self)
      end
      def batch_get_graph(name)
        Arango::Graph.batch_get(name, database: self)
      end
      alias fetch_graph get_graph
      alias retrieve_graph get_graph
      alias batch_fetch_graph batch_get_graph
      alias batch_retrieve_graph batch_get_graph

      def new_graph(name)
        Arango::Graph.new(name, database: self)
      end

      def list_graphs
        Arango::Graph.list(database: self)
      end
      def batch_list_graphs
        Arango::Graph.batch_list(database: self)
      end

      def drop_graph(name)
        Arango::Graph.drop(name, database: self)
      end
      def batch_drop_graph(name)
        Arango::Graph.batch_drop(name, database: self)
      end
      alias delete_graph drop_graph
      alias destroy_graph drop_graph
      alias batch_delete_graph batch_drop_graph
      alias batch_destroy_graph batch_drop_graph

      def exist_graph?(name)
        Arango::Graph.exist?(name, database: self)
      end
      def batch_exist_graph?(name)
        Arango::Graph.batch_exist?(name, database: self)
      end
      alias graph_exist? exist_graph?
    end
  end
end
