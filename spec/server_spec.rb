require 'spec_helper'

describe "Arango::Server" do
  context "Administration" do
    before :all do
      @server = connect
    end

    it "all_endpoints" do
      expect(@server.all_endpoints.first).to have_key(:endpoint)
    end

    it "available?" do
      expect(@server.available?).to be true
    end

    # it "cluster_endpoints" do
    #   expect(@server.cluster_endpoints).to eq('')
    # end

    it "echo" do
      result = @server.echo(test: 'result')
      expect(result).to eq(test: 'result')
    end

    it "engine" do
      expect(%w[mmfiles rocksdb]).to include(@server.engine.name)
    end

    it "mmfiles?" do
      expect([true, false]).to include(@server.mmfiles?)
      expect(@server.mmfiles?).to be(!@server.rocksdb?)
    end

    it "rocksdb?" do
      expect([true, false]).to include(@server.rocksdb?)
      expect(@server.rocksdb?).to be(!@server.mmfiles?)
    end

    it "log" do
      result = @server.log
      expect(result.total_amount > 1).to be true
    end

    it "log_level" do
      result = @server.log_level
      expect(result.general).to eq('INFO')
    end

    it "log_level=" do
      ll = @server.log_level
      result = @server.log_level=ll
      expect(result.general).to eq('INFO')
    end

    it "mode" do
      expect(@server.mode).to eq(:default)
    end

    it "mode=" do
      expect(@server.mode = :default).to eq(:default)
    end

    it "read_only?" do
      expect(@server.read_only?).to be false
    end

    it "reload_routing" do
      expect(@server.reload_routing).to be true
    end

    it "role" do
      expect(%w[SINGLE COORDINATOR PRIMARY SECONDARY AGENT UNDEFINED]).to include(@server.role)
    end

    it "server_id" do
      expect(@server.server_id).to be_a(String)
    end

    it "statistics" do
      expect(@server.statistics.server[:uptime]).to be_a(Numeric)
    end

    it "statistics_description" do
      expect(@server.statistics_description.groups).to include({ group: "system", name: "Process Statistics",
                                                                 description: "Statistics about the ArangoDB process" })
    end

    it 'status' do
      expect(@server.status.server).to eq('arango')
    end

    it 'time' do
      expect(@server.time).to be_a(Numeric)
    end

    it 'version' do
      expect(@server.version.version).to be_a(String)
    end
  end

  context "Tasks" do
    before :all do
      @server = connect
    end

    it "all_endpoints" do
      expect(@server.all_endpoints.first).to have_key(:endpoint)
    end
  end
end