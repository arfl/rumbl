# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Rumbl.Repo.insert!(%Rumbl.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Rumbl.{Repo, User, Category}

Repo.insert(%User{username: "jose", name: "Jose Valim"})
Repo.insert(%User{username: "redrapids", name: "Brus Red"})
Repo.insert(%User{username: "cmccord", name: "Chris Cord"})

for category <- ~w(Action Drama Romance Comedy Sci-fi) do
  Repo.insert!(%Category{name: category})
end
