import Config

# Used for the sample/test code
config :khafra_search, Khafra.Sample.Repo,
  database: "test",
  username: "settler",
  password: "settler",
  hostname: "localhost"

config :khafra_search, :repo, Khafra.Sample.Repo

config :sql, pools: [
  default: [
    username: "settler",
    password: "settler",
    hostname: "localhost",
    database: "test",
    adapter: SQL.Adapters.Postgres,
    ssl: false
  ]
]
