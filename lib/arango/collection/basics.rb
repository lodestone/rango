module Arango
  class Collection
    module Basics

      def self.included(base)
        base.instance_exec do
          # Takes a hash and instantiates a Arango::Collection object from it.
          #
          # @param collection_hash [Hash]
          # @return [Arango::Collection]
          def from_h(collection_hash, database: nil)
            collection_hash.merge!(database: database) if database
            collection = Arango::Collection.new(collection_hash.delete(:name), **collection_hash)
            collection
          end

          # Takes a Arango::Result and instantiates a Arango::Collection object from it.
          #
          # @param arango_result [Arango::Result]
          # @return [Arango::Collection]
          def from_result(arango_result, database: nil)
            from_h(arango_result.to_h, database: database)
          end

          def all(exclude_system: true, database:)
            query = { excludeSystem: exclude_system }
            result = request("GET", "_api/collection", query: query, key: :result)
            result.map do |c|
              Arango::Collection.from_h(c.to_h, database: database)
            end
          end

          def get(name, database:)
            result = database.request("GET", "_api/collection/#{name}")
            Arango::Collection.from_result(result, database: database)
          end
          alias fetch get
          alias retrieve get

          def list(exclude_system: true, database:)
            query = { excludeSystem: exclude_system }
            result = database.request("GET", "_api/collection", query: query, key: :result)
            result.map { |c| c[:name] }
          end

          def drop(name, database:)
            database.request("DELETE", "_api/collection/#{name}")
            nil
          end
          alias delete drop
          alias destroy drop

          def exist?(name, exclude_system: true, database:)
            result = list(exclude_system: exclude_system, database: database)
            result.include?(name)
          end
        end
      end

      def info

      end

      def change_property

      end

      def properties
        @database.request("GET", "_api/collection/#{@name}/properties")
      end

      def properties=
        @database.request("GET", "_api/collection/#{@name}/properties")
      end

      def revision
        @database.request("GET", "_api/collection/#{@name}/revision", key: :revision)
      end

      def indexes

      end

      def rename(new_name)
        body = { name: new_name }
        result = @database.request("PUT", "_api/collection/#{@name}/rename", body: body)
        return_element(result)
      end

      def truncate
        result = @database.request("PUT", "_api/collection/#{@name}/truncate")
        return_element(result)
      end

      def drop
        @database.request("DELETE", "_api/collection/#{@name}")
        nil
      end
    end
  end
end
