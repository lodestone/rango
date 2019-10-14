module Arango
  module Edge
    module Mixin
      def included(base)
        base.include(Arango::Edge::InstanceMethods)
      end
    end
  end
end
