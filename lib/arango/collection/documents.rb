module Arango
  class Collection
    module Documents
      def create_document(document, wait_for_sync: nil)
        Arango::Document.new(document, collection: self, wait_for_sync: wait_for_sync).create
      end

      def create_documents(array_of_property_hashes, wait_for_sync: nil)
        Arango::Document.create_documents(array_of_property_hashes, collection: self, wait_for_sync: wait_for_sync)
      end

      def exist_document?(*args)
        Arango::Document.exist?(*args, collection: self)
      end
      alias document_exist? exist_document?

      def get_document(name, rev: nil, from: nil, to: nil)
        Arango::Document.get(name: name, collection: self, body: body, rev: rev, from: from, to: to)
      end
      alias fetch_document get_document
      alias retrieve_document get_document

      def get_documents(name, rev: nil, from: nil, to: nil)
        Arango::Document.get_documents(name: name, collection: self, body: body, rev: rev, from: from, to: to)
      end
      alias fetch_documents get_documents
      alias retrieve_documents get_documents

      def all_documents(offset: 0, limit: nil, batch_size: nil)
        return nil if type == :edge
        Arango::Document.all(offset: offset, limit: limit, batch_size: batch_size, collection: self)
      end

      def list_documents(offset: 0, limit: nil, batch_size: nil)
        Arango::Document.list(offset: offset, limit: limit, batch_size: batch_size, collection: self)
      end

      def replace_document(document)
        Arango::Document.replace(document)
      end

      def replace_documents(documents_array, wait_for_sync: nil, ignore_revs: nil, return_old: nil, return_new: nil)
        Arango::Document.replace_documents(documents_array)
      end

      def save_document(document)
        Arango::Document.save(documents_array)
      end
      alias update_document save_document

      def save_documents(documents_array, wait_for_sync: nil, ignore_revs: nil)
        Arango::Document.save_documents(documents_array)
      end
      alias update_documents save_documents

      def drop_document(document_or_key)
        Arango::Document.drop(document)
      end
      alias delete_document drop_document
      alias destroy_document drop_document

      def drop_documents(documents_array, wait_for_sync: nil, return_old: nil)
        Arango::Document.drop_documents(documents_array)
      end
      alias delete_documents drop_documents
      alias destroy_documents drop_documents
    end
  end
end
