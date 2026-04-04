import Config

# Used for the sample/test code
config :khafra_search, Khafra.Sample.Repo,
  database: "test",
  username: "settler",
  password: "settler",
  hostname: "localhost"

config :khafra_search, ecto_repos: [Khafra.Sample.Repo]

config :khafra_search, :repo, Khafra.Sample.Repo
