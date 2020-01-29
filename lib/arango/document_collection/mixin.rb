module Arango
  module DocumentCollection
    STATES = %i[unknown new_born unloaded loaded being_unloaded deleted loading] # do not sort, index is used
    TYPES = %i[unknown unknown document edge] # do not sort, index is used

    module Mixin
      def self.included(base)
        base.extend(Arango::DocumentCollection::ClassMethods)
        base.include(Arango::DocumentCollection::InstanceMethods)
        base.include(Arango::DocumentCollection::Documents)

        include Arango::Helper::Satisfaction

        # extend Arango::Helper::RequestMethod

        include Arango::DocumentCollection::Documents
        include Arango::DocumentCollection::Indexes
      end
    end
  end
end
