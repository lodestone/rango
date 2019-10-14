module Arango
  module VertexCollection
    class Base
      def inherited(base)
        base.include(Arango::VertexCollection::Mixin)
      end
    end
  end
end
