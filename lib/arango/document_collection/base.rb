module Arango
  module DocumentCollection
    class Base
      def inherited(base)
        base.include Arango::DocumentCollection::Mixin
      end
    end
  end
end
