module Arango
  module Document
    module Mixin
      def included(base)
        base.include Arango::Helper::Satisfaction
        base.extend(Arango::Document::ClassMethods)
        base.include(Arango::Document::InstanceMethods)
      end
    end
  end
end
