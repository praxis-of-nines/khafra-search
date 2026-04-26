defmodule Khafra.Sample.Repo.Migrations.SampleSqlData do
  use Ecto.Migration

  @titles [
    "The Silent Forest",
    "Echoes of Tomorrow",
    "Beneath the Crimson Sky",
    "The Last Cartographer",
    "Whispers in the Dark",
    "A Thousand Paper Cranes",
    "The Clockwork Garden",
    "Songs of the Wandering Star",
    "The Forgotten Lighthouse",
    "Embers of the North"
  ]

  @authors [
    "Ada Hawthorne",
    "Marcus Vale",
    "Elena Cortez",
    "Jiro Tanaka",
    "Priya Kapoor",
    "Oskar Lindgren",
    "Nadia Abrams",
    "Felix Moreau",
    "Yara Saleh",
    "Theodore Quinn"
  ]

  def change do
    create table("book", primary_key: false) do
      add :id,          :integer, primary_key: true
      add :title,       :text
      add :description, :text
      add :author,      :text
    end

    rows =
      for {{title, author}, idx} <- Enum.with_index(Enum.zip(@titles, @authors), 1) do
        [
          id: idx,
          title: title,
          description: "A captivating tale by #{author} exploring themes #{Enum.random(1..1000)}.",
          author: author
        ]
      end

    execute(fn -> repo().insert_all("book", rows) end, fn -> repo().delete_all("book") end)
  end
end
