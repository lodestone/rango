module Arango
  module Vertex
    class Base
      def inherited(base)
        base.include(Arango::Vertex::Mixin)
      end
    end
  end
end
