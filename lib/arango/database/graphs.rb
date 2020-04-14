module Arango
  class Database
    module GraphAccess
      def all_graphs
        Arango::Graph::Base.all(database: self)
      end
      def batch_all_graps
        Arango::Graph::Base.batch_all(database: self)
      end

      # TODO issmart, edgedefinitions, waitforsync, options
      def create_graph(name:, edge_definitions: [], is_smart: nil)
        Arango::Graph::Base.new(name: name, edge_definitions: edge_definitions, is_smart: is_smart, database: self).create
      end
      def batch_create_graph(name:, edge_definitions: [], is_smart: nil)
        Arango::Graph::Base.new(name: name, edge_definitions: edge_definitions, is_smart: is_smart, database: self).batch_create
      end

      def get_graph(name:)
        Arango::Graph::Base.get(name: name, database: self)
      end
      def batch_get_graph(name:)
        Arango::Graph::Base.batch_get(name: name, database: self)
      end
      alias fetch_graph get_graph
      alias retrieve_graph get_graph
      alias batch_fetch_graph batch_get_graph
      alias batch_retrieve_graph batch_get_graph

      def new_graph(name:, edge_definitions: [], is_smart: nil)
        Arango::Graph::Base.new(name: name, edge_definitions: edge_definitions, is_smart: is_smart, database: self)
      end

      def list_graphs
        Arango::Graph::Base.list(database: self)
      end
      def batch_list_graphs
        Arango::Graph::Base.batch_list(database: self)
      end

      def drop_graph(name:)
        Arango::Graph::Base.drop(name: name, database: self)
      end
      def batch_drop_graph(name:)
        Arango::Graph::Base.batch_drop(name: name, database: self)
      end
      alias delete_graph drop_graph
      alias destroy_graph drop_graph
      alias batch_delete_graph batch_drop_graph
      alias batch_destroy_graph batch_drop_graph

      def graph_exists?(name:)
        Arango::Graph::Base.exists?(name: name, database: self)
      end
      def batch_graph_exists?(name:)
        Arango::Graph::Base.batch_exists?(name: name, database: self)
      end
    end
  end
end
