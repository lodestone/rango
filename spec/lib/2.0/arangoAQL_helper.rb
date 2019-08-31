require_relative './../../spec_helper'

describe Arango::AQL do
  context "#new" do
    it "create a new AQL instance" do
      myAQL = @myDatabase.aql query: "FOR u IN MyCollection RETURN u.num"
      expect(myAQL.query).to eq "FOR u IN MyCollection RETURN u.num"
    end

    it "instantiate size" do
      @myAQL.batch_size = 5
      expect(@myAQL.batch_size).to eq 5
    end
  end

  context "#execute" do
    it "execute Transaction" do
      @myAQL.execute
      expect(@myAQL.result.length).to eq 5
    end

    it "execute again Transaction" do
      @myAQL.next
      expect(@myAQL.result.length).to eq 5
    end
  end

  context "#info" do
    it "explain" do
      expect(@myAQL.explain[:cacheable]).to be true
    end

    it "parse" do
      expect(@myAQL.parse[:parsed]).to be true
    end

    it "properties" do
      expect(@myDatabase.query_properties[:enabled]).to be true
    end

    it "current" do
      expect(@myDatabase.current_query.empty?).to be true
    end

    it "slow" do
      expect(@myDatabase.slow_queries.empty?).to be true
    end
  end

  context "#delete" do
    it "stopSlow" do
      expect(@myDatabase.stop_slow_queries).to be true
    end

    it "kill" do
      error = nil
      begin
        @myAQL.kill
      rescue Arango::ErrorDB => e
        error = e.error_num
      end
      expect(error.class).to be Integer
    end

    it "changeProperties" do
      result = @myDatabase.change_query_properties max_slow_queries: 65
      expect(result[:maxSlowQueries]).to eq 65
    end
  end
end
