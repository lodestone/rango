module Arango
  module EdgeCollection
    module Mixin
      def included(base)
        base.include(Arango::EdgeCollection::EdgeAccess)
      end
    end
  end
end
