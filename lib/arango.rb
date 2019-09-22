module Arango
  def self.current_database
    @current_database
  end

  def self.current_database=(d)
    @current_database = d
  end

  def self.current_server
    @current_server
  end

  def self.current_server=(s)
    @current_server = s
  end

  def self.connect_to(username: "root", password:, host: "localhost", warning: true, port: "8529", return_output: false,
      pool: true, pool_size: 5, timeout: 5, tls: false, database: nil)
    @current_server = Arango::Server.new(username: username, password: password, host: host, warning: warning, port: port,
                                         return_output: return_output, pool: pool, pool_size: pool_size, timeout: timeout, tls: tls)
    @current_database = @current_server.get_database(database) if database
    @current_server
  end
end
