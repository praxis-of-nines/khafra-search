import Config

# Used for the sample/test code
config :khafra_search, Khafra.Sample.Repo,
  database: "test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :khafra_search, :repo, Khafra.Sample.Repo

config :sql, pools: [
  default: [
    username: "postgres",
    password: "postgres",
    hostname: "localhost",
    database: "test",
    adapter: SQL.Adapters.Postgres,
    ssl: false
  ]
]
