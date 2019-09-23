module Arango
  class Collection
    module Documents
      def new_document(document, wait_for_sync: nil)
        Arango::Document.new(document, collection: self, wait_for_sync: wait_for_sync)
      end

      def create_document(document, wait_for_sync: nil)
        Arango::Document.new(document, collection: self, wait_for_sync: wait_for_sync).create
      end
      def batch_create_document(document, wait_for_sync: nil)
        Arango::Document.new(document, collection: self, wait_for_sync: wait_for_sync).batch_create
      end

      def create_documents(array_of_property_hashes, wait_for_sync: nil)
        Arango::Document.create_documents(array_of_property_hashes, collection: self, wait_for_sync: wait_for_sync)
      end
      def batch_create_documents(array_of_property_hashes, wait_for_sync: nil)
        Arango::Document.batch_create_documents(array_of_property_hashes, collection: self, wait_for_sync: wait_for_sync)
      end

      def exist_document?(*args)
        Arango::Document.exist?(*args, collection: self)
      end
      def batch_exist_document?(*args)
        Arango::Document.batch_exist?(*args, collection: self)
      end
      alias document_exist? exist_document?
      alias batch_document_exist? batch_exist_document?

      def get_document(name, rev: nil, from: nil, to: nil)
        Arango::Document.get(name: name, collection: self, body: body, rev: rev, from: from, to: to)
      end
      def batch_get_document(name, rev: nil, from: nil, to: nil)
        Arango::Document.batch_get(name: name, collection: self, body: body, rev: rev, from: from, to: to)
      end
      alias fetch_document get_document
      alias retrieve_document get_document
      alias batch_fetch_document batch_get_document
      alias batch_retrieve_document batch_get_document

      def get_documents(name, rev: nil, from: nil, to: nil)
        Arango::Document.get_documents(name: name, collection: self, body: body, rev: rev, from: from, to: to)
      end
      def batch_get_documents(name, rev: nil, from: nil, to: nil)
        Arango::Document.batch_get_documents(name: name, collection: self, body: body, rev: rev, from: from, to: to)
      end
      alias fetch_documents get_documents
      alias retrieve_documents get_documents
      alias batch_fetch_documents batch_get_documents
      alias batch_retrieve_documents batch_get_documents

      def all_documents(offset: 0, limit: nil, batch_size: nil)
        return nil if type == :edge
        Arango::Document.all(offset: offset, limit: limit, batch_size: batch_size, collection: self)
      end
      def batch_all_documents(offset: 0, limit: nil, batch_size: nil)
        return nil if type == :edge
        Arango::Document.batch_all(offset: offset, limit: limit, batch_size: batch_size, collection: self)
      end

      def list_documents(offset: 0, limit: nil, batch_size: nil)
        Arango::Document.list(offset: offset, limit: limit, batch_size: batch_size, collection: self)
      end
      def batch_list_documents(offset: 0, limit: nil, batch_size: nil)
        Arango::Document.batch_list(offset: offset, limit: limit, batch_size: batch_size, collection: self)
      end

      def replace_document(document)
        Arango::Document.replace(document)
      end
      def batch_replace_document(document)
        Arango::Document.batch_replace(document)
      end

      def replace_documents(documents_array, wait_for_sync: nil, ignore_revs: nil, return_old: nil, return_new: nil)
        Arango::Document.replace_documents(documents_array)
      end
      def batch_replace_documents(documents_array, wait_for_sync: nil, ignore_revs: nil, return_old: nil, return_new: nil)
        Arango::Document.batch_replace_documents(documents_array)
      end

      def save_document(document)
        Arango::Document.save(document)
      end
      def batch_save_document(document)
        Arango::Document.batch_save(document)
      end
      alias update_document save_document

      def save_documents(documents_array, wait_for_sync: nil, ignore_revs: nil)
        Arango::Document.save_documents(documents_array)
      end
      def batch_save_documents(documents_array, wait_for_sync: nil, ignore_revs: nil)
        Arango::Document.batch_save_documents(documents_array)
      end
      alias update_documents save_documents

      def drop_document(document)
        Arango::Document.drop(document)
      end
      def batch_drop_document(document)
        Arango::Document.batch_drop(document)
      end
      alias delete_document drop_document
      alias destroy_document drop_document
      alias batch_delete_document batch_drop_document
      alias batch_destroy_document batch_drop_document

      def drop_documents(documents_array, wait_for_sync: nil, return_old: nil)
        Arango::Document.drop_documents(documents_array)
      end
      def batch_drop_documents(documents_array, wait_for_sync: nil, return_old: nil)
        Arango::Document.batch_drop_documents(documents_array)
      end
      alias delete_documents drop_documents
      alias destroy_documents drop_documents
      alias batch_delete_documents batch_drop_documents
      alias batch_destroy_documents batch_drop_documents
    end
  end
end
