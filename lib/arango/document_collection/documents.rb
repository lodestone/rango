module Arango
  module DocumentCollection
    module Documents
      def new_document(key: nil, attributes: {}, wait_for_sync: nil)
        Arango::Document::Base.new(key: key, attributes: attributes, collection: self, wait_for_sync: wait_for_sync)
      end

      def create_document(key: nil, attributes: {}, wait_for_sync: nil)
        Arango::Document::Base.new(key: key, attributes: attributes, collection: self, wait_for_sync: wait_for_sync).create
      end
      def batch_create_document(key: nil, attributes: {}, wait_for_sync: nil)
        Arango::Document::Base.new(key: key, attributes: attributes, collection: self, wait_for_sync: wait_for_sync).batch_create
      end

      def create_documents(array_of_attributes_hashes, wait_for_sync: nil)
        Arango::Document::Base.create_documents(array_of_attributes_hashes, collection: self, wait_for_sync: wait_for_sync)
      end
      def batch_create_documents(array_of_attributes_hashes, wait_for_sync: nil)
        Arango::Document::Base.batch_create_documents(array_of_attributes_hashes, collection: self, wait_for_sync: wait_for_sync)
      end

      def document_exists?(key: nil, attributes: {}, match_rev: nil)
        Arango::Document::Base.exists?(key: key, attributes: attributes, match_rev: match_rev, collection: self)
      end
      def batch_document_exists?(key: nil, attributes: {}, match_rev: nil)
        Arango::Document::Base.batch_exists?(key: key, attributes: attributes, match_rev: match_rev, collection: self)
      end

      def get_document(key: nil, attributes: {})
        Arango::Document::Base.get(key: key, attributes: attributes, collection: self)
      end
      def batch_get_document(key: nil, attributes: {})
        Arango::Document::Base.batch_get(key: key, attributes: attributes, collection: self)
      end
      alias fetch_document get_document
      alias retrieve_document get_document
      alias batch_fetch_document batch_get_document
      alias batch_retrieve_document batch_get_document

      def get_documents(keys)
        Arango::Document::Base.get_documents(keys, collection: self)
      end
      def batch_get_documents(keys)
        Arango::Document::Base.batch_get_documents(keys, collection: self)
      end
      alias fetch_documents get_documents
      alias retrieve_documents get_documents
      alias batch_fetch_documents batch_get_documents
      alias batch_retrieve_documents batch_get_documents

      def all_documents(offset: 0, limit: nil, batch_size: nil)
        Arango::Document::Base.all(offset: offset, limit: limit, batch_size: batch_size, collection: self)
      end
      def batch_all_documents(offset: 0, limit: nil, batch_size: nil)
        Arango::Document::Base.batch_all(offset: offset, limit: limit, batch_size: batch_size, collection: self)
      end

      def list_documents(offset: 0, limit: nil, batch_size: nil)
        Arango::Document::Base.list(offset: offset, limit: limit, batch_size: batch_size, collection: self)
      end
      def batch_list_documents(offset: 0, limit: nil, batch_size: nil)
        Arango::Document::Base.batch_list(offset: offset, limit: limit, batch_size: batch_size, collection: self)
      end

      def replace_document(document)
        Arango::Document::Base.replace(document)
      end
      def batch_replace_document(document)
        Arango::Document::Base.batch_replace(document)
      end

      def replace_documents(documents_array, wait_for_sync: nil, ignore_revs: nil, return_old: nil, return_new: nil)
        Arango::Document::Base.replace_documents(documents_array, wait_for_sync: wait_for_sync, ignore_revs: ignore_revs,
                                                 return_old: return_old, return_new: return_new)
      end
      def batch_replace_documents(documents_array, wait_for_sync: nil, ignore_revs: nil, return_old: nil, return_new: nil)
        Arango::Document::Base.batch_replace_documents(documents_array, wait_for_sync: wait_for_sync, ignore_revs: ignore_revs,
                                                       return_old: return_old, return_new: return_new)
      end

      def save_document(document)
        Arango::Document::Base.save(document)
      end
      def batch_save_document(document)
        Arango::Document::Base.batch_save(document)
      end
      alias update_document save_document

      def save_documents(documents_array, wait_for_sync: nil, ignore_revs: nil)
        Arango::Document::Base.save_documents(documents_array, wait_for_sync: wait_for_sync, ignore_revs: ignore_revs)
      end
      def batch_save_documents(documents_array, wait_for_sync: nil, ignore_revs: nil)
        Arango::Document::Base.batch_save_documents(documents_array, wait_for_sync: wait_for_sync, ignore_revs: ignore_revs)
      end
      alias update_documents save_documents

      def drop_document(key: nil, attributes: {})
        Arango::Document::Base.drop(key: key, attributes: attributes, collection: self)
      end
      def batch_drop_document(key: nil, attributes: {})
        Arango::Document::Base.batch_drop(key: key, attributes: attributes, collection: self)
      end
      alias delete_document drop_document
      alias destroy_document drop_document
      alias batch_delete_document batch_drop_document
      alias batch_destroy_document batch_drop_document

      def drop_documents(documents_array)
        Arango::Document::Base.drop_documents(documents_array, collection: self)
      end
      def batch_drop_documents(documents_array)
        Arango::Document::Base.batch_drop_documents(documents_array, collection: self)
      end
      alias delete_documents drop_documents
      alias destroy_documents drop_documents
      alias batch_delete_documents batch_drop_documents
      alias batch_destroy_documents batch_drop_documents
    end
  end
end
