module Arango
  module EdgeCollection
    module ClassMethods
      def new(database: Arango.current_database, graph: nil,
              name:, id: nil, is_system: false, status: nil, type: :edge,
              properties: {})
        case type
        when :document
          Arango::DocumentCollection::Base.new(database: database, graph: graph,
                                               name: name, id: nil, is_system: false, status: status, type: :document,
                                               properties: properties)
        when :edge
          super(database: database, graph: graph,
                name: name, id: id, status: status, type: :edge, is_system: is_system,
                properties: properties)
        else raise "unknown type"
        end
      end
    end
  end
end
