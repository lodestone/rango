module Arango
  module Requests
    module Administration
      class SetLogLevel < Arango::Request
        request_method :put

        uri_template "/_admin/log/level"

        body :agency
        body :agencycomm
        # TODO -> - <-
        # body :audit-authentication
        # body :audit-authorization
        # body :audit-collection
        # body :audit-database
        # body :audit-document
        # body :audit-service
        # body :audit-view
        body :authentication
        body :authorization
        body :cache
        body :cluster
        body :collector
        body :communication
        body :compactor
        body :config
        body :datafiles
        body :development
        body :engines
        body :general
        body :graphs
        body :heartbeat
        body :ldap
        body :memory
        body :mmap
        body :performance
        body :pregel
        body :queries
        body :replication
        body :requests
        body :rocksdb
        body :ssl
        body :startup
        body :supervision
        body :syscall
        body :threads
        body :trx
        body :v8
        body :views

        code 200, :success
        code 400, "Request body invalid!"
        code 405, "Invalid request method!"
        code 500, "Server out of memory!"
      end
    end
  end
end
