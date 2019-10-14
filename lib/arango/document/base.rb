module Arango
  module Document
    class Base
      def inherited(base)
        base.include Arango::Document::Mixin
      end
    end
  end
end
