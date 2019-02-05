defmodule Khafra.Generate.GenerateFromCommand do
  @moduledoc """
  Functions that are responsible for generating data directly from command to files
  """
 
  def wordform(word_source, word_destination) when is_binary(word_source) and is_binary(word_destination) do
    {:ok, file} = File.open "sphinx/wordforms.txt", [:append]

    _ = IO.binwrite file, "#{word_source} > #{word_destination}\n"

    _ = File.close file

    {:ok, "#{word_source} > #{word_destination}"}
  end

  def wordform(_, _), do: {:error, "wordform only accepts binary source and destination arguments"}
end