module Arango
  module Graph
    class Base
      def inherited(base)
        base.include Arango::Graph::Mixin
      end
    end
  end
end
