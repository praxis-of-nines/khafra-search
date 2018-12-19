# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# Database configuration.  The Repo you will index
config :khafra_search, :source_sqldb,
  adapter: :postgres, # :mysql
  database: "",
  username: "",
  password: "",
  hostname: "localhost"

# Command defaults for indexer settings
config :khafra_search, :indexer,
  mem_limit: "1024M"

# Common defaults for search daemon settings
config :khafra_search, :searchd,
  listen_sphinx: "9312",
  listen_mysql: "9306:mysql41",
  listen_http: "9308",
  log: "../../log/searchd.log",
  query_log: "../../log/query.log",
  pid_file: "../../data/searchd.pid",
  read_timeout: "2"

# Common index defaults: by default the parent of any index created
config :khafra_search, :index_defaults,
  type: "plain",
  source: {:sql, :source_sqldb},
  path: "../../data/default",
  morphology: "none",
  min_stemming_len: "1",
  min_word_len: "1",
  min_infix_len: "2",
  html_strip: "0",
  preopen: "0"

# Query source that tests using the Khafra test index
#
# Parent: 
#   Source inherits attributes from the parent and defaults to source_sqldb, 
#   the source set up from Repo (if Repo exists)
# Query: 
#   SQL structured query used to build index
# Attributes: 
#   Indexed fields, returned with query and usable as filters
# Fields: 
#   Indexed fields for search but not returned, stored or usable as filters
config :khafra_search, :source_test,
  parent: :source_sqldb,
  query: """
    SELECT * \\
    FROM test;
  """,
  attributes: [poster_id: :integer],
  fields: [blog_post: :string]

# Index using test source
config :khafra_search, :index_test,
  parent: :index_defaults,
  source: :source_test

# List your indices for Khafra to include in env (allows to switch some off per environment)
#config :khafra_search, 
#  indices: [:index_defaults, :index_test]