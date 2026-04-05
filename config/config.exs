# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
import Config

config :khafra_search,
  env: :dev

# Strategy for updating after a schema insert/update
config :khafra_search, :strategies,
  update_strategy: :immediate,
  update_all_strategy: :queue,
  application_start: :create_tables_if_not_exist

# Cluster+Shard settings. Agents should map to deployed servers.
# This config will be used in created tables by default but can
# be overridden with options
config :khafra_search, :distribution,
  tables: :all,
  agents: [
    "localhost:9312:default_shard"
  ]

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
  log: "../../../log/searchd.log",
  query_log: "../../../log/query.log",
  pid_file: "../../data/searchd.pid",
  network_timeout: "2"

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

config :lapin, :connections, [
  [
    module: Khafra.Queue.ManageTableConsumer,
    exchanges: [
      table_manager_exchange: [
        type: :direct,
        options: [durable: true],
        binds: [
          manage_tables: [routing_key: "manage_tables_key"]
        ]
      ]
    ],
    queues: [
      manage_tables: [
        options: [durable: true],
        binds: [
          table_manager_exchange: [routing_key: "manage_tables_key"]
        ]
      ]
    ],
    consumers: [
      [queue: "manage_tables"]
    ]
  ],
  [
    module: Khafra.Queue.ManageTableProducer,
    producers: [
      [exchange: "table_manager_exchange"]
    ]
  ]
]


import_config "#{config_env()}.exs"
