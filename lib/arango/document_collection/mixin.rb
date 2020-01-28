module Arango
  module DocumentCollection
    STATES = %i[unknown new_born unloaded loaded being_unloaded deleted loading] # do not sort, index is used
    TYPES = %i[unknown unknown document edge] # do not sort, index is used

    module Mixin
      def included(base)
        base.extend(Arango::DocumentCollection::ClassMethods)
        base.include(Arango::DocumentCollection::InstanceMethods)
        base.include(Arango::DocumentCollection::Documents)

        include Arango::Helper::Satisfaction

        # extend Arango::Helper::RequestMethod

        include Arango::Collection::Documents
        include Arango::Collection::Indexes

        base.instance_exec do
          alias fetch get
          alias retrieve get
          alias batch_fetch batch_get
          alias batch_retrieve batch_get

          alias delete drop
          alias destroy drop
          alias batch_delete batch_drop
          alias batch_destroy batch_drop
        end
      end
    end
  end
end
