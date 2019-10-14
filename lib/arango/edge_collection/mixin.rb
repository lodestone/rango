module Arango
  module EdgeCollection
    module Mixin
      def included(base)
        base.extend(Arango::EdgeCollection::ClassMethods)
        base.include(Arango::EdgeCollection::Edges)
      end
    end
  end
end
