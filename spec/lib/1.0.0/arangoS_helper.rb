require_relative './../../spec_helper'

describe ArangoServer do
  context "#general" do
    it "address" do
      expect(ArangoServer.address).to eq "localhost:8529"
    end

    it "username" do
      expect(ArangoServer.username).to eq "root"
    end

    it "request" do
      expect(ArangoServer.request[":body"].class).to be NilClass
    end
  end

  context "#user" do
    it "setup a global user" do
      ArangoServer.user = "MyUser2"
      expect(ArangoServer.user).to eq "MyUser2"
    end
  end

  context "#monitoring" do
    it "log" do
      expect(ArangoServer.log["totalAmount"]).to be >= 0
    end

    it "reload" do
      expect(ArangoServer.reload).to be true
    end

    it "statistics" do
      expect(ArangoServer.statistics["enabled"]).to be true
    end

    it "statisticsDescription" do
      expect(ArangoServer.statisticsDescription["groups"][0].nil?).to be false
    end

    it "role" do
      expect(ArangoServer.role.class).to eq String
    end

    it "server" do
      expect(ArangoServer.server.class).to eq String
    end

    it "serverID" do
      expect(ArangoServer.serverId.to_i).to be >= 1
    end

    it "clusterStatistics" do
      expect(ArangoServer.clusterStatistics.class).to eq String
    end
  end

  context "#endpoints" do
    it "endpoints" do
      expect(ArangoServer.endpoints[0].keys[0]).to eq "endpoint"
    end

    it "users" do
      expect(ArangoServer.users.length).to be >= 1
    end
  end

  context "#async" do
    it "create async" do
      ArangoServer.async = "store"
      expect(ArangoServer.async).to eq "store"
    end
  end

  context "#batch" do
    it "batch" do
      ArangoServer.async = false
      ArangoCollection.new.create
      queries = [{
        "type": "POST",
        "address": "/_db/MyDatabase/_api/collection",
        "body": {"name": "newCOLLECTION"},
        "id": "1"
      },
      {
        "type": "GET",
        "address": "/_api/database",
        "id": "2"
      }]
      expect((ArangoServer.batch queries: queries).class).to be String
    end

    it "createDumpBatch" do
      expect((ArangoServer.createDumpBatch ttl: 100).to_i).to be > 1
    end

    it "prolongDumpBatch" do
      dumpBatchID = ArangoServer.createDumpBatch ttl: 100
      expect((ArangoServer.prolongDumpBatch ttl: 100, id: dumpBatchID).to_i).to be > 1
    end

    it "destroyDumpBatch" do
      dumpBatchID = ArangoServer.createDumpBatch ttl: 100
      expect(ArangoServer.destroyDumpBatch id: dumpBatchID).to be true
    end
  end

  context "#task" do
    it "tasks" do
      result = ArangoServer.tasks
      expect(result[0].id.class).to be String
    end
  end

  context "#miscellaneous" do
    it "version" do
      expect(ArangoServer.version["server"]).to eq "arango"
    end

    it "propertyWAL" do
      ArangoServer.changePropertyWAL historicLogfiles: 14
      expect(ArangoServer.propertyWAL["historicLogfiles"]).to eq 14
    end

    it "flushWAL" do
      expect(ArangoServer.flushWAL).to be true
    end

    it "transactions" do
      expect(ArangoServer.transactions["runningTransactions"]).to eq 0
    end

    it "time" do
      expect(ArangoServer.time.class).to be Float
    end

    it "echo" do
      expect(ArangoServer.echo["user"]).to eq "root"
    end

    it "databaseVersion" do
      expect(ArangoServer.databaseVersion.to_i).to be >= 1
    end

    it "sleep" do
      expect(ArangoServer.sleep duration: 10).to be >= 1
    end

    # it "shutdown" do
    #   result = ArangoServer.shutdown
    #   `sudo service arangodb restart`
    #   expect(result).to eq "OK"
    # end

    # it "test" do
    #   print ArangoServer.test body: {"num" => 1}
    # end
  end


end