module Arango
  module EdgeCollection
    class Base
      def inherited(base)
        base.include(Arango::EdgeCollection::Mixin)
      end
    end
  end
end
