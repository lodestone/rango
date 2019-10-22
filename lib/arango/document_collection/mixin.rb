module Arango
  module DocumentCollection
    STATES = %i[unknown new_born unloaded loaded being_unloaded deleted loading] # do not sort, index is used
    TYPES = %i[unknown unknown document edge] # do not sort, index is used

    module Mixin
      def included(base)
        base.extend(Arango::DocumentCollection::ClassMethods)
        base.include(Arango::DocumentCollection::InstanceMethods)
        base.include(Arango::DocumentCollection::DocumentAccess)

        include Arango::Helper::Satisfaction

        extend Arango::Helper::RequestMethod

        include Arango::Collection::Documents
        include Arango::Collection::Indexes
      end
    end
  end
end
