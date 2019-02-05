defmodule Mix.Tasks.Khafra.Gen.Wordform do
  use Mix.Task

  @shortdoc "Generate a Sphinx wordform"

  @moduledoc """
  Wordforms allow you to specify synonym meanings in words so they are indexed as equivalent

  See more: http://sphinxsearch.com/docs/manual-2.3.2.html#conf-wordforms

  Generating a wordform will add it to your wordform configuration. To activate in your index add
  to your Elixir config something like: 

  ## Example

      config :khafra_search, :index_defaults,
        wordforms: "[cwd!]/sphinx/data/wordforms.txt"

  ## Example

      > mix khafra.gen.wordform "s02e02" "season 2 episode 2"
      > mix khafra.gen.wordform "walks" "walk"
      > mix khafra.gen.wordform "walked" "walk"
      > mix khafra.gen.wordform "walking" "walk"
  """
  alias Khafra.Generate.GenerateFromCommand, as: Gen

  def run([word_source, word_destination]) do
    {_, result} = Gen.wordform(word_source, word_destination)

    Mix.shell.info result
  end

  def run(_) do
    Mix.shell.info "Include a word form and a destination word as arguments"
  end
end