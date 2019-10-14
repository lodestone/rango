module Arango
  module Document
    module Mixin
      def included(base)
        base.include Arango::Helper::Satisfaction
        base.extend(Arango::Helper::RequestMethod)
        base.extend(Arango::Document::ClassMethods)
        base.include Arango::Helper::CollectionAssignment
        base.include(Arango::Document::InstanceMethods)

        # not sure

        base.include Arango::Helper::Return

        base.include Arango::Helper::Traversal
      end
    end
  end
end
