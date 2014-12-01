neo4j_url = ENV["GRAPHENEDB_URL"] || "http://localhost:7474" # default to local server

uri = URI.parse(neo4j_url)

require 'neography'

Neography.configure do |conf|
  conf.protocol       = "http://"
  conf.server = uri.host
  conf.port = uri.port
  conf.directory      = ""  # prefix this path with '/'
  conf.cypher_path    = "/cypher"
  conf.gremlin_path   = "/ext/GremlinPlugin/graphdb/execute_script"
  conf.log_file       = "neography.log"
  conf.log_enabled    = false
  conf.max_threads    = 20
  conf.authentication = nil  # 'basic' or 'digest'
  conf.username       = nil
  conf.password       = nil
  conf.parser         = MultiJsonParser
  conf.authentication = 'basic'
  conf.username = uri.user
  conf.password = uri.password
end

# # these are the default values:
# Neography.configure do |config|
#   config.protocol       = "http://"
#   config.server         = "localhost"
#   config.port           = 7474
#   config.directory      = ""  # prefix this path with '/'
#   config.cypher_path    = "/cypher"
#   config.gremlin_path   = "/ext/GremlinPlugin/graphdb/execute_script"
#   config.log_file       = "neography.log"
#   config.log_enabled    = false
#   config.max_threads    = 20
#   config.authentication = nil  # 'basic' or 'digest'
#   config.username       = nil
#   config.password       = nil
#   config.parser         = MultiJsonParser
# end
