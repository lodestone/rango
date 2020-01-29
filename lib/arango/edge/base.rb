module Arango
  module Edge
    class Base
      def self.inherited(base)
        base.include Arango::Edge::Mixin
      end
    end
  end
end
