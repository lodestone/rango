require 'spec_helper'

describe "Arango::Task" do
  before :all do
    @server = connect
  end

  # context "" do
  #   before do
  #     @myTask = @myDatabase.task(id: "mytaskid", name: "MyTaskID", command: "(function(params) { require('@arangodb').print(params); })(params)", params: {foo: "bar", bar: "foo"}, period: 60).create
  #   end
  # end

  context "Server" do
    before :each do
      begin
        @server.delete_task('1')
      rescue
      end
      begin
        @server.delete_task('2')
      rescue
      end
      begin
        @server.delete_task('3')
      rescue
      end
    end

    after :each do
      begin
        @server.delete_task('1')
      rescue
      end
      begin
        @server.delete_task('2')
      rescue
      end
      begin
        @server.delete_task('3')
      rescue
      end
    end

    it "new_task" do
      task = @server.new_task('1')
      expect(task).to be_a Arango::Task
    end

    it "get_task" do
      task = @server.new_task('1')
      task.command = '1+1'
      task.period = 2
      task.create
      expect(task).to be_a Arango::Task
      t = @server.get_task('1')
      expect(t).to be_a Arango::Task
      expect(t.id).to eq('1')
    end

    it "all_tasks" do
      %w[1 2 3].each do |id|
        @server.new_task(id, command: '1+1', period: 2).create
      end
      all_tasks = @server.all_tasks
      expect(all_tasks.size).to eq 3
      expect(all_tasks.map(&:id).sort).to eq %w[1 2 3]
    end

    it "list_tasks" do
      %w[1 2 3].each do |id|
        @server.new_task(id, command: '1+1', period: 2).create
      end
      list = @server.list_tasks
      expect(list.size).to eq 3
      expect(list.sort).to eq %w[1 2 3]
    end

    it "delete_tasks" do
      %w[1 2 3].each do |id|
        @server.new_task(id, command: '1+1', period: 2).create
      end
      @server.delete_task('2')
      list = @server.list_tasks
      expect(list.size).to eq 2
      expect(list.sort).to eq %w[1 3]
    end
  end

  context "Database" do
    before :all do
      begin
        @server.drop_database("TaskDatabase")
      rescue
      end
      @database = @server.create_database("TaskDatabase")
    end

    before :each do
      begin
        @database.delete_task('1')
      rescue
      end
      begin
        @database.delete_task('2')
      rescue
      end
      begin
        @database.delete_task('3')
      rescue
      end
    end

    after :each do
      begin
        @database.delete_task('1')
      rescue
      end
      begin
        @database.delete_task('2')
      rescue
      end
      begin
        @database.delete_task('3')
      rescue
      end
    end

    after :all do
      @server.drop_database("TaskDatabase")
    end

    it "new_task" do
      task = @database.new_task('1')
      expect(task).to be_a Arango::Task
    end

    it "get_task" do
      task = @database.new_task('1')
      task.command = '1+1'
      task.period = 2
      task.create
      expect(task).to be_a Arango::Task
      t = @database.get_task('1')
      expect(t).to be_a Arango::Task
      expect(t.id).to eq('1')
    end

    it "all_tasks" do
      %w[1 2 3].each do |id|
        @database.new_task(id, command: '1+1', period: 2).create
      end
      all_tasks = @database.all_tasks
      expect(all_tasks.size).to eq 3
      expect(all_tasks.map(&:id).sort).to eq %w[1 2 3]
    end

    it "list_tasks" do
      %w[1 2 3].each do |id|
        @database.new_task(id, command: '1+1', period: 2).create
      end
      list = @database.list_tasks
      expect(list.size).to eq 3
      expect(list.sort).to eq %w[1 2 3]
    end

    it "delete_tasks" do
      %w[1 2 3].each do |id|
        @database.new_task(id, command: '1+1', period: 2).create
      end
      @database.delete_task('2')
      list = @database.list_tasks
      expect(list.size).to eq 2
      expect(list.sort).to eq %w[1 3]
    end
  end

  #   it "create new instance" do
  #     myArangoTask = Arango::Task.new "mytaskid", name: "MyTaskID",
  #                                     command: "(function(params) { require('@arangodb').print(params); })(params)",
  #                                     params: {foo: "bar", bar: "foo"}, period: 2, database: @myDatabase
  #     expect(myArangoTask.params[:foo]).to eq "bar"
  #   end
  #
  #   it "create a new Task instance" do
  #     myArangoTask = Arango::Task.new name: "MyTaskID",
  #                                     command: "(function(params) { require('@arangodb').print(params); })(params)",
  #                                     params: {foo: "bar", bar: "foo"}, period: 2, database: @myDatabase
  #     expect([BigDecimal, Float].include?(myArangoTask.create.created.class)).to eq true
  #   end
  #
  #   it "create a new Task instance with ID" do
  #     myArangoTask = Arango::Task.new id: "mytaskid2", name: "MyTaskID",
  #                                     command: "(function(params) { require('@arangodb').print(params); })(params)",
  #                                     params: {"foo2": "bar2", "bar2": "foo2"}, period: 2, database: @myDatabase
  #     myArangoTask.create
  #     expect(myArangoTask.params[:foo2]).to eq "bar2"
  #   end
  #
  #   it "duplicate a Task instance with ID" do
  #     val = nil
  #     begin
  #       myArangoTask = Arango::Task.new id: "mytaskid2", name: "MyTaskID",
  #                                       command: "(function(params) { require('@arangodb').print(params); })(params)",
  #                                       params: {"foo21": "bar2", "bar21": "foo21"}, period: 2, database: @myDatabase
  #       myArangoTask.create
  #     rescue Arango::Error => e
  #       val = e.message
  #     end
  #     expect(val).to eq "duplicate task id"
  #   end
  #
  #   it "retrieve lists" do
  #     myArangoTask = Arango::Task.new name: "MyTaskID",
  #                                     command: "(function(params) { require('@arangodb').print(params); })(params)",
  #                                     params: {"foo2": "bar2", "bar2": "foo2"}, period: 2, database: @myDatabase
  #     myArangoTask.create
  #     result = @myDatabase.tasks
  #     result = result.map{|x| x.database.name}
  #     expect(result.include? 'MyDatabase').to be true
  #   end
  #
  #   it "retrieve" do
  #     myArangoTask = Arango::Task.new name: "MyTaskID",
  #                                     command: "(function(params) { require('@arangodb').print(params); })(params)",
  #                                     params: {"foo2": "bar2", "bar2": "foo2"}, period: 2, database: @myDatabase
  #     myArangoTask.create
  #     expect(myArangoTask.retrieve.params[:foo2]).to eq "bar2"
  #   end
  #
  #   it "destroy" do
  #     myArangoTask = Arango::Task.new id: "mytaskid2", database: @myDatabase
  #     expect(myArangoTask.destroy).to be true
  #   end
  #
  # context "Database" do
  #   it "database" do
  #     expect(@myTask.database.class).to be Arango::Database
  #   end
  # end
end
